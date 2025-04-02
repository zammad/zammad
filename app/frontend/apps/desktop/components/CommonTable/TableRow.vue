<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TableItem } from './types'

export interface Props {
  item: TableItem
  onClickRow?: (tableItem: TableItem) => void
  isRowSelected?: boolean
  hasCheckbox?: boolean
  noAutoStriping?: boolean
  isStriped?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'click-row': [TableItem]
}>()

const rowId = 'selectable-table-row'

const rowEventHandler = computed(() =>
  (props.onClickRow || props.hasCheckbox) && !props.item.disabled
    ? {
        attrs: {
          'aria-describedby': rowId,
          tabindex: props.hasCheckbox ? -1 : 0,
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
    : { attrs: {}, events: {} },
)

const hasScreenReaderHelpText = computed(
  () => !!document?.getElementById(rowId),
)
</script>

<template>
  <tr
    :class="{
      'odd:bg-blue-200 odd:dark:bg-gray-700': !noAutoStriping,
      'bg-blue-200 dark:bg-gray-700': isStriped === true,
      '!bg-blue-800': !hasCheckbox && isRowSelected,
    }"
    style="clip-path: xywh(0 0 100% 100% round 0.375rem)"
    data-test-id="table-row"
    v-bind="rowEventHandler.attrs"
    v-on="rowEventHandler.events"
  >
    <slot :is-row-selected="isRowSelected" />

    <template v-if="!hasScreenReaderHelpText">
      <Teleport to="body">
        <p
          v-if="rowEventHandler.attrs['aria-describedby']"
          :id="rowId"
          class="sr-only absolute"
        >
          {{ __('Select table row') }}
        </p>
      </Teleport>
    </template>
  </tr>
</template>
