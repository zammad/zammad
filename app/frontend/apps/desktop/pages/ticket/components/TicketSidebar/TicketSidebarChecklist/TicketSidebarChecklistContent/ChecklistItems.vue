<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { animations } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { computed, type Ref, ref, useTemplateRef } from 'vue'

import { type ChecklistItem as ChecklistItemType } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'
import ChecklistItem from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/TicketSidebarChecklistContent/ChecklistItem.vue'

interface Props {
  title: string
  items: ChecklistItemType[]
  readOnly: boolean
  isUpdatingOrder: boolean
  isEditingNewItem: boolean
  isUpdatingChecklistTitle: boolean
  noDefaultTitle: boolean
  updatingItemIds: Set<ID>
  onEditItem: (item: ChecklistItemType) => Promise<void>
  onUpdateTitle: (title: string) => Promise<void>
}

const emit = defineEmits<{
  'add-item': []
  'remove-item': [ChecklistItemType]
  'set-item-checked': [ChecklistItemType]
  'save-order': [Array<ChecklistItemType>, stopReordering: () => void]
}>()

const props = defineProps<Props>()

const isReordering = ref(false)
const checklistCopy = ref<ChecklistItemType[]>([]) // Create a copy if reordering is aborted

const checklistItems = computed({
  get: () => (isReordering.value ? checklistCopy.value : [...props.items]),
  set: (value: ChecklistItemType[]) => {
    checklistCopy.value = value
  },
})

const checklistInstance = useTemplateRef('checklist')
const containerElement = useTemplateRef<HTMLElement>('container')
const checklistTitleInstance = useTemplateRef('title')

dragAndDrop({
  parent: containerElement as Ref<HTMLElement>,
  values: checklistCopy,
  plugins: [animations()],
  draggable: (el) => {
    // Library bug: The draggable attribute is not set always
    // Workaround to set the attribute manually
    // https://github.com/formkit/drag-and-drop/issues/96

    el.setAttribute('draggable', isReordering.value.toString())

    return isReordering.value
  },
  dropZoneClass: 'opacity-0',
})

const focusNewItem = () => {
  checklistInstance.value?.at(-1)?.focusInput()
}

const addNewItem = () => {
  emit('add-item')
}

const editItem = async (item: ChecklistItemType) => {
  return props.onEditItem(item)
}

const resetOrder = () => {
  isReordering.value = false
  checklistCopy.value = []
}

const saveOrder = () => {
  emit('save-order', checklistCopy.value, resetOrder)
}

const startReordering = () => {
  isReordering.value = true
  checklistCopy.value = props.items
}

defineExpose({
  focusTitle: () => checklistTitleInstance.value?.activateEditing(),
  quitItemEditing: (index: number) =>
    checklistInstance.value?.at(index)?.quitEditing(),
  quitReordering: resetOrder,
  focusNewItem,
})
</script>

<template>
  <div class="grid grid-cols-2 gap-x-2">
    <CommonInlineEdit
      id="checklistTitle"
      ref="title"
      data-test-id="checklistTitle"
      :class="{
        'pointer-events-none opacity-60': isUpdatingChecklistTitle,
      }"
      :value="title"
      :initial-edit-value="noDefaultTitle ? title : ''"
      block
      :disabled="readOnly"
      :loading="isUpdatingChecklistTitle"
      :aria-disabled="isUpdatingChecklistTitle"
      :label-attrs="{
        role: 'heading',
        'aria-level': '3',
      }"
      :label="$t('Edit checklist title')"
      class="col-span-2 mb-3 w-full"
      @submit-edit="onUpdateTitle"
    />
    <TransitionGroup
      v-if="checklistItems.length"
      ref="container"
      tag="ul"
      name="none"
      class="col-span-2 mb-2 space-y-2"
      :class="{ 'pointer-events-none opacity-60': isUpdatingOrder }"
    >
      <template v-for="item in checklistItems" :key="item.id">
        <li v-if="readOnly" class="flex gap-2 py-2">
          <template v-if="!item.ticketReference">
            <CommonIcon
              tabindex="0"
              class="me-0.5 ms-1 mt-1 text-gray-100 outline-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-neutral-400"
              size="xs"
              role="checkbox"
              aria-readonly="true"
              :aria-checked="item.checked"
              :aria-labelledby="`checklist-item-${getIdFromGraphQLId(item.id)}`"
              :name="item.checked ? 'check-square-fill' : 'square-fill'"
            />
            <CommonInlineEdit
              :id="`checklist-item-${getIdFromGraphQLId(item.id)}`"
              detect-links
              :classes="{
                label: 'dark:text-white text-black',
              }"
              disabled
              :value="item.text || '-'"
            />
          </template>
          <!-- No CommonLabel to preserve the link detection -->
          <CommonTicketLabel
            v-else
            :unauthorized="!item.ticketReference.ticket"
            :ticket="item.ticketReference.ticket"
          />
        </li>

        <ChecklistItem
          v-else
          ref="checklist"
          :item="item"
          :class="{
            'cursor-grab active:cursor-grabbing': isReordering,
            'pointer-events-none opacity-60': updatingItemIds.has(item.id),
          }"
          :is-updating="updatingItemIds.has(item.id)"
          :data-test-id="item.id"
          :aria-disabled="updatingItemIds.has(item.id)"
          :is-reordering="isReordering"
          @remove-item="$emit('remove-item', $event)"
          @set-item-checked="$emit('set-item-checked', $event)"
          @edit-item="editItem"
        />
      </template>
    </TransitionGroup>

    <CommonLabel v-else class="col-span-2 text-neutral-500" size="small">
      {{ $t('No checklist items yet') }}
    </CommonLabel>

    <template v-if="checklistItems.length > 1 && !readOnly">
      <Transition mode="out-in">
        <CommonButton
          v-if="!isReordering"
          prefix-icon="list"
          :disabled="isEditingNewItem"
          @click="startReordering"
          >{{ $t('Reorder') }}
        </CommonButton>
        <CommonButton
          v-else
          :prefix-icon="isReordering ? 'check2' : 'list'"
          :disabled="isUpdatingOrder"
          @click="resetOrder"
          >{{ $t('Cancel') }}
        </CommonButton>
      </Transition>
    </template>

    <template v-if="!readOnly">
      <Transition mode="out-in">
        <CommonButton
          v-if="!isReordering"
          v-tooltip="$t('Create a new checklist item')"
          size="medium"
          :disabled="isEditingNewItem"
          class="col-end-3 justify-self-end ltr:mr-2 rtl:ml-2"
          icon="plus-square-fill"
          @click="addNewItem"
        />
        <CommonButton
          v-else
          size="small"
          variant="submit"
          class="col-end-3 justify-self-end"
          :disabled="isUpdatingOrder"
          @click="saveOrder"
        >
          {{ $t('Save') }}
        </CommonButton>
      </Transition>
    </template>
  </div>
</template>
