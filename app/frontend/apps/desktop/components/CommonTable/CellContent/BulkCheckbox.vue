<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import stopEvent from '#shared/utils/events.ts'

import type { TableAdvancedItem } from '#desktop/components/CommonTable/types.ts'

interface Props {
  items: TableAdvancedItem[]
  itemIds?: Set<ID>
  disabled?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'select-all': []
  'deselect-all': []
}>()

const selectableItems = computed(() =>
  props.items.filter((item) => (item.policy ? item.policy.update : !item.disabled)),
)

const checkboxIds = computed(() => selectableItems.value.map((item) => `cell-checkbox-${item.id}`))

const hasNoSelection = computed(() => !props.itemIds || props.itemIds.size === 0)

const hasPartialSelection = computed(
  () =>
    props.itemIds && props.itemIds.size > 0 && props.itemIds.size < selectableItems.value.length,
)

const hasFullSelection = computed(() => props.itemIds?.size === selectableItems.value.length)

const checkboxIcon = computed(() => {
  if (hasFullSelection.value) return 'check-square'
  if (hasPartialSelection.value) return 'dash-square'
  return 'square'
})

const updateBulkItems = (event: MouseEvent | KeyboardEvent) => {
  if (props.disabled) return

  stopEvent(event)

  if (hasNoSelection.value || hasPartialSelection.value) {
    emit('select-all')
    return
  }

  emit('deselect-all')
}
</script>

<template>
  <div
    v-tooltip="
      hasNoSelection || hasPartialSelection ? $t('Select all entries') : $t('Clear selection')
    "
    role="checkbox"
    class="group/checkbox flex size-full cursor-pointer items-center justify-center text-stone-200 group-hover:text-black! group-active:text-white! hover:text-black focus-visible:rounded-xs focus-visible:outline focus-visible:outline-none dark:text-neutral-500 group-hover:dark:text-white! dark:hover:text-white"
    :class="{
      'text-gray-100! dark:text-neutral-400!': hasPartialSelection || hasFullSelection,
      'cursor-not-allowed! opacity-50': disabled,
    }"
    :aria-disabled="props.disabled ? 'true' : 'false'"
    tabindex="0"
    :aria-checked="hasPartialSelection ? 'mixed' : `${hasFullSelection}`"
    :aria-controls="checkboxIds.join(' ')"
    @click="updateBulkItems($event)"
    @keydown.enter="updateBulkItems($event)"
    @keydown.space="updateBulkItems($event)"
  >
    <CommonIcon
      decorative
      class="shrink-0 group-focus-visible/checkbox:rounded-xs group-focus-visible/checkbox:outline group-focus-visible/checkbox:outline-offset-1 group-focus-visible/checkbox:outline-blue-800"
      size="xs"
      :name="checkboxIcon"
    />
  </div>
</template>
