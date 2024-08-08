<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { animations } from '@formkit/drag-and-drop'
import { dragAndDrop } from '@formkit/drag-and-drop/vue'
import { computed, ref } from 'vue'

import type { ChecklistItem as ChecklistItemType } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import ChecklistItem from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistItem.vue'
// import ChecklistTicketItem from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistTicketItem.vue'

interface Props {
  title: string
  items: ChecklistItemType[]
  readOnly: boolean
  noDefaultTitle: boolean
}

const emit = defineEmits<{
  'add-item': []
  'remove-item': [ChecklistItemType]
  'set-item-checked': [ChecklistItemType]
  'edit-item': [ChecklistItemType]
  'save-order': [Array<ChecklistItemType>]
  'update-title': [string]
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

const checklistNodes = ref<InstanceType<typeof ChecklistItem>[]>()
const checklistContainer = ref<HTMLElement>()
const checklistTitleComponent = ref<InstanceType<typeof CommonInlineEdit>>()

dragAndDrop({
  parent: checklistContainer,
  values: checklistCopy,
  plugins: [animations()],
  draggable() {
    return isReordering.value
  },
  dropZoneClass: 'opacity-0',
  touchDropZoneClass: 'opacity-0',
})

// Actions
const focusNewItem = () => {
  checklistNodes.value?.at(-1)?.focusInput()
}

const onAddNewItem = () => {
  emit('add-item')
}

const resetOrder = () => {
  isReordering.value = false
  checklistCopy.value = []
}

const saveOrder = () => {
  emit('save-order', checklistCopy.value)
  isReordering.value = false
  checklistCopy.value = []
}

const startReordering = () => {
  isReordering.value = true
  checklistCopy.value = props.items
}

defineExpose({
  focusTitle: () => checklistTitleComponent.value?.activateEditing(),
  quitItemEditing: (index: number) =>
    checklistNodes.value?.at(index)?.quitEditing(),
  focusNewItem,
})
</script>

<template>
  <div class="grid grid-cols-2 gap-x-2">
    <CommonInlineEdit
      id="checklistTitle"
      ref="checklistTitleComponent"
      :value="title"
      :initial-edit-value="noDefaultTitle ? title : ''"
      block
      :disabled="readOnly"
      :label-attrs="{
        role: 'heading',
        'aria-level': '3',
      }"
      :label="$t('Edit checklist title')"
      class="col-span-2 mb-3 w-full"
      @submit-edit="$emit('update-title', $event)"
    />

    <TransitionGroup
      v-if="checklistItems.length"
      ref="checklistContainer"
      tag="ul"
      name="none"
      class="col-span-2 mb-2 space-y-2"
    >
      <template v-for="item in checklistItems" :key="item.id">
        <div v-if="readOnly" class="flex gap-2 py-2">
          <CommonIcon
            tabindex="0"
            class="mt-1 text-gray-100 outline-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-neutral-400"
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
            :value="item.text as string"
          />
        </div>
        <!--        <ChecklistTicketItem v-else-if="true" :item="item" />-->
        <ChecklistItem
          v-else
          ref="checklistNodes"
          :item="item"
          :class="{
            'cursor-grab active:cursor-grabbing': isReordering,
          }"
          :is-reordering="isReordering"
          @remove-item="$emit('remove-item', $event)"
          @set-item-checked="$emit('set-item-checked', $event)"
          @edit-item="$emit('edit-item', $event)"
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
          @click="startReordering"
          >{{ $t('Reorder') }}</CommonButton
        >
        <CommonButton
          v-else
          :prefix-icon="isReordering ? 'check2' : 'list'"
          @click="resetOrder"
          >{{ $t('Cancel') }}</CommonButton
        >
      </Transition>
    </template>

    <template v-if="!readOnly">
      <Transition mode="out-in">
        <CommonButton
          v-if="!isReordering"
          v-tooltip="$t('Create a new checklist item')"
          size="medium"
          class="col-end-3 justify-self-end ltr:mr-2 rtl:ml-2"
          icon="plus-square-fill"
          @click="onAddNewItem"
        />
        <CommonButton
          v-else
          size="small"
          variant="submit"
          class="col-end-3 justify-self-end"
          @click="saveOrder"
        >
          {{ $t('Save') }}
        </CommonButton>
      </Transition>
    </template>
  </div>
</template>
