<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TableItem } from '#desktop/components/CommonSimpleTable/types.ts'

export interface Props {
  item: TableItem
  onClickRow?: (tableItem: TableItem) => void
  isRowSelected?: boolean
  hasCheckbox?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'click-row': [TableItem]
}>()

const rowEventHandler = computed(() => {
  return (props.onClickRow || props.hasCheckbox) && !props.item.disabled
    ? {
        attrs: {
          role: props.hasCheckbox ? undefined : 'button',
          tabindex: props.hasCheckbox ? -1 : 0,
          ariaLabel: __('Select table row'),
          class:
            'group focus-visible:outline-transparent cursor-pointer active:bg-blue-800 active:dark:bg-blue-800 focus-visible:bg-blue-800 focus-visible:dark:bg-blue-900 focus-within:text-white hover:bg-blue-600 dark:hover:bg-blue-900',
        },
        events: {
          click: () => {
            ;(document.activeElement as HTMLElement)?.blur()
            emit('click-row', props.item)
          },
          keydown: (event: KeyboardEvent) => {
            if (event.key !== 'Enter') return
            emit('click-row', props.item)
          },
        },
      }
    : { attrs: {}, events: {} }
})
</script>

<template>
  <tr
    class="odd:bg-blue-200 odd:dark:bg-gray-700"
    :class="{
      '!bg-blue-800': !hasCheckbox && isRowSelected,
    }"
    style="clip-path: xywh(0 0 100% 100% round 0.375rem)"
    data-test-id="simple-table-row"
    v-bind="rowEventHandler.attrs"
    v-on="rowEventHandler.events"
  >
    <slot :is-row-selected="isRowSelected" />
  </tr>
</template>
