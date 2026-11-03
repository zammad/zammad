<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { HTMLAttributes } from 'vue'

interface GridColumnHeader {
  key: string
  text: string
  label: string
}

// A grid of day, month or year cells, rendered the same way by the desktop and the mobile panel
// up to the classes. The day grid adds the weekday headers and, if asked, the calendar weeks.
interface Props {
  rows: Date[][]
  label: string
  cellText: (date: Date) => string
  cellLabel?: (date: Date) => string
  cellClasses: (date: Date) => HTMLAttributes['class']
  isSelected: (date: Date) => boolean
  isFocused: (date: Date) => boolean
  isDisabled: (date: Date) => boolean
  tableClass?: HTMLAttributes['class']
  columnHeaders?: GridColumnHeader[]
  headingClass?: HTMLAttributes['class']
  // A leading column with a header for each row, the calendar week in the day grid.
  rowHeader?: (row: Date[]) => string
  rowHeaderLabel?: string
  rowHeaderClass?: HTMLAttributes['class']
}

withDefaults(defineProps<Props>(), {
  tableClass: 'w-full border-separate border-spacing-1',
})

const emit = defineEmits<{
  select: [date: Date]
  keydown: [event: KeyboardEvent]
}>()
</script>

<template>
  <table role="grid" :class="tableClass" :aria-label="label">
    <thead v-if="columnHeaders">
      <tr>
        <th v-if="rowHeader" scope="col" :class="rowHeaderClass" :aria-label="rowHeaderLabel" />
        <th
          v-for="header in columnHeaders"
          :key="header.key"
          scope="col"
          :class="headingClass"
          :aria-label="header.label"
        >
          {{ header.text }}
        </th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="(row, rowIndex) in rows" :key="rowIndex">
        <th v-if="rowHeader" scope="row" :class="rowHeaderClass" data-test-id="field-date-week">
          {{ rowHeader(row) }}
        </th>
        <td
          v-for="date in row"
          :key="date.toISOString()"
          class="p-0"
          :aria-selected="isSelected(date)"
        >
          <!-- A roving tab stop: the arrow keys move within the grid, Tab leaves it. -->
          <button
            type="button"
            :class="cellClasses(date)"
            :tabindex="isFocused(date) ? 0 : -1"
            :data-focus-target="isFocused(date) || undefined"
            :aria-label="cellLabel?.(date)"
            :aria-disabled="isDisabled(date) || undefined"
            @click="emit('select', date)"
            @keydown="emit('keydown', $event)"
          >
            {{ cellText(date) }}
          </button>
        </td>
      </tr>
    </tbody>
  </table>
</template>
