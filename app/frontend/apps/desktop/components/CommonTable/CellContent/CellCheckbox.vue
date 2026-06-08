<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import stopEvent from '#shared/utils/events.ts'

import type { TableAdvancedItem } from '#desktop/components/CommonTable/types.ts'

interface Props {
  item: TableAdvancedItem
  itemIds?: Set<ID>
  disabled?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{ toggle: [{ shiftKey: boolean }] }>()

const hasRowId = computed(() => props.itemIds?.has(props.item.id))

const checkboxId = computed(() => `cell-checkbox-${props.item.id}`)

const checkboxIcon = computed(() => (hasRowId.value ? 'check-square' : 'square'))

const disabled = computed(() =>
  // Disabled can be set from outside on all checkboxes
  // Disabled can be set on the individual item
  props.disabled ? true : props.item.disabled || props.item.policy?.update === false,
)

const emitToggle = (event: MouseEvent | KeyboardEvent) => {
  if (disabled.value) return

  stopEvent(event)
  emit('toggle', { shiftKey: event.shiftKey })
}
</script>

<template>
  <!-- eslint-disable-next-line vuejs-accessibility/interactive-supports-focus-->
  <div
    :id="checkboxId"
    v-tooltip="
      disabled ? undefined : hasRowId ? $t('Deselect this entry') : $t('Select this entry')
    "
    role="checkbox"
    class="group/checkbox flex size-full cursor-pointer items-center justify-center text-stone-200 group-hover:text-black! group-active:text-white! focus-visible:outline-none dark:text-neutral-500 group-hover:dark:text-white!"
    :class="{
      'before:absolute before:top-0 before:z-20 before:h-full before:w-2 before:bg-blue-800 ltr:before:left-0 rtl:before:right-0':
        hasRowId,
      'text-gray-100! dark:text-neutral-400!': hasRowId,
      'cursor-not-allowed! opacity-50 group-hover:text-gray-100! group-hover:dark:text-neutral-400!':
        disabled,
    }"
    :tabindex="disabled ? -1 : 0"
    :aria-disabled="!!disabled"
    :aria-description="
      disabled && props.item.policy ? $t('You do not have permission to update') : undefined
    "
    :aria-checked="!!hasRowId"
    @click="emitToggle"
    @keydown.enter="emitToggle"
    @keydown.space="emitToggle"
  >
    <CommonIcon
      decorative
      class="shrink-0 group-focus-visible/checkbox:rounded-xs group-focus-visible/checkbox:outline group-focus-visible/checkbox:outline-offset-1 group-focus-visible/checkbox:outline-blue-800"
      size="xs"
      :name="checkboxIcon"
    />
  </div>
</template>
