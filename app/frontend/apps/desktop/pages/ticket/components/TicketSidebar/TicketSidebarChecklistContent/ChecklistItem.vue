<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import type { ChecklistItem as ChecklistItemType } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

interface Props {
  item: ChecklistItemType
  isReordering: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'remove-item': [ChecklistItemType]
  'set-item-checked': [ChecklistItemType]
  'edit-item': [ChecklistItemType]
}>()

const inlineEditComponent = ref<InstanceType<typeof CommonInlineEdit>>()

const removeItem = () => {
  emit('remove-item', props.item)
}

const setItemCheckedState = (newValue: boolean) => {
  if (props.item.checked === newValue) return
  emit('set-item-checked', { ...props.item, checked: newValue })
}

const editItem = (newValue: string) => {
  emit('edit-item', { ...props.item, text: newValue })
}

const isEditing = ref(false)

const actions: MenuItem[] = [
  {
    key: 'check',
    label: __('Check item'),
    icon: 'check2-square',
    onClick: () => setItemCheckedState(true),
    show: (entity) => !entity?.checked,
  },
  {
    key: 'uncheck',
    label: __('Uncheck item'),
    icon: 'check2-square',
    onClick: () => setItemCheckedState(false),
    show: (entity) => entity?.checked,
  },
  {
    key: 'edit',
    icon: 'pencil',
    label: __('Edit item'),
    onClick: () => inlineEditComponent.value?.activateEditing(),
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
  focusInput: () => inlineEditComponent.value?.activateEditing(),
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
    <Transition name="none" mode="out-in">
      <CommonIcon
        v-if="isReordering"
        name="grip-vertical"
        class="mt-1.5 inline-block shrink-0"
        size="xs"
      />
      <FormKit
        v-else
        :id="`checked_${item.id}`"
        type="checkbox"
        :classes="{
          outer: 'flex items-center shrink-0 self-start mt-0.5',
          inner: 'rtl:ml-0 ltr:mr-0',
        }"
        :model-value="item.checked as boolean"
        :name="`checkbox-checklist-item-${getIdFromGraphQLId(item.id)}`"
        :aria-label="item.text"
        @update:model-value="setItemCheckedState($event as boolean)"
      />
    </Transition>

    <CommonInlineEdit
      ref="inlineEditComponent"
      v-model:editing="isEditing"
      detect-links
      alternative-background
      block
      :value="item.text as string"
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
      v-if="!inlineEditComponent?.isEditing && !isReordering"
      button-size="small"
      class="mt-0.5 flex"
      placement="arrowEnd"
      :actions="actions"
      :entity="item"
    />
  </li>
</template>
