<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, useTemplateRef } from 'vue'

import { type ChecklistItem as ChecklistItemType } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'

interface Props {
  item: ChecklistItemType
  isReordering: boolean
  isUpdating?: boolean
  onEditItem: (item: ChecklistItemType) => Promise<void>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'remove-item': [ChecklistItemType]
  'set-item-checked': [ChecklistItemType]
}>()

const isTicketItem = computed(() => !!props.item.ticketReference)

const noAccessToLinkedTicket = computed(
  () => !props.item.ticketReference?.ticket,
)

const inlineEditInstance = useTemplateRef('inline-edit')

const removeItem = () => {
  emit('remove-item', props.item)
}

const setItemCheckedState = (newValue: boolean) => {
  if (props.item.checked === newValue) return
  emit('set-item-checked', { ...props.item, checked: newValue })
}

const editItem = async (newValue: string) => {
  return props.onEditItem({ ...props.item, text: newValue })
}

const isEditing = ref(false)

const actions: MenuItem[] = [
  {
    key: 'check',
    label: __('Check item'),
    icon: 'check2-square',
    onClick: () => setItemCheckedState(true),
    show: (entity) => !entity?.checked && !isTicketItem.value,
  },
  {
    key: 'uncheck',
    label: __('Uncheck item'),
    icon: 'check2-square',
    onClick: () => setItemCheckedState(false),
    show: (entity) => entity?.checked && !isTicketItem.value,
  },
  {
    key: 'edit',
    icon: 'pencil',
    label: __('Edit item'),
    show: () => !isTicketItem.value,
    onClick: () => inlineEditInstance.value?.activateEditing(),
  },
  {
    key: 'remove',
    label: __('Remove item'),
    variant: 'danger',
    icon: 'trash3',
    onClick: () => removeItem(),
  },
]

defineExpose({
  focusInput: () => inlineEditInstance.value?.activateEditing(),
  quitEditing: () => {
    isEditing.value = false
  },
})
</script>

<template>
  <li
    class="flex min-h-10 gap-2 overflow-x-clip rounded-lg bg-blue-200 p-2 text-stone-200 dark:bg-gray-700 dark:text-neutral-500"
    :class="{ 'items-center': isEditing }"
  >
    <template v-if="isReordering">
      <CommonIcon
        name="grip-vertical"
        class="mt-1.5 inline-block shrink-0"
        size="xs"
      />
      <CommonIcon
        v-if="!isTicketItem"
        tabindex="0"
        class="mt-1.5 shrink-0 text-gray-100 outline-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:text-neutral-400"
        size="xs"
        role="checkbox"
        aria-readonly="true"
        :aria-checked="item.checked"
        :aria-labelledby="`checklist-item-${getIdFromGraphQLId(item.id)}`"
        :name="item.checked ? 'check-square-fill' : 'square-fill'"
      />
    </template>
    <template v-else>
      <FormKit
        v-if="!isTicketItem"
        :id="`checked_${item.id}`"
        type="checkbox"
        :classes="{
          outer: 'flex items-center shrink-0 self-start mt-0.5',
          inner: 'rtl:!ml-0 ltr:!mr-0',
        }"
        :model-value="item.checked"
        :name="`checkbox-checklist-item-${getIdFromGraphQLId(item.id)}`"
        :aria-label="item.text"
        @update:model-value="setItemCheckedState($event as boolean)"
      />
    </template>

    <CommonTicketLabel
      v-if="isTicketItem"
      :classes="{
        indicator: isReordering ? '-ms-0.5' : '',
      }"
      :unauthorized="noAccessToLinkedTicket"
      :ticket="item.ticketReference?.ticket"
    />

    <CommonInlineEdit
      v-else
      ref="inline-edit"
      v-model:editing="isEditing"
      detect-links
      alternative-background
      block
      :loading="isUpdating"
      :value="item.text"
      :placeholder="$t('Text or ticket identifier')"
      :class="{ 'pointer-events-none': isReordering }"
      :classes="{
        label: 'dark:text-white text-black',
        input: 'dark:text-white text-black',
      }"
      :disabled="isReordering"
      @submit-edit="editItem"
    />

    <CommonActionMenu
      v-if="!inlineEditInstance?.isEditing && !isReordering"
      button-size="small"
      class="mt-0.5 flex"
      placement="arrowEnd"
      :actions="actions"
      :entity="item"
    />
  </li>
</template>
