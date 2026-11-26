<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isSameMonth, isToday } from 'date-fns'
import { computed, ref, useTemplateRef } from 'vue'

import {
  TIME_KINDS,
  timeSegmentSpec,
  type SegmentKind,
} from '#shared/components/Form/fields/FieldDate/dateFormat.ts'
import FieldDateGrid from '#shared/components/Form/fields/FieldDate/FieldDateGrid.vue'
import {
  MONTH_CELL_FORMAT,
  MONTH_TITLE_FORMAT,
  useCalendarPanel,
  weekNumber,
  YEAR_FORMAT,
  type CalendarPanelProps,
} from '#shared/components/Form/fields/FieldDate/useCalendarPanel.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import { useTimeFieldEntry } from './useTimeFieldEntry.ts'

interface Props extends CalendarPanelProps {
  // A leading column with the calendar week of each row.
  showWeekNumbers?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  commit: [date: Date]
  done: []
}>()

const container = useTemplateRef('container')

const {
  calendar,
  commitDisplayHour,
  commitTime,
  fmt,
  focusActive,
  hoursDisplay,
  isFocused,
  isSelected,
  minutesDisplay,
  monthRows,
  nextLabel,
  onGridKeydown: moveGridFocus,
  prevLabel,
  timeBase,
  title,
  titleLabel,
  toggleMeridiem,
  weekdayHeaders,
  weeks,
  yearRows,
} = useCalendarPanel(props, {
  container,
  onCommit: (date) => emit('commit', date),
  onDone: () => emit('done'),
})

const { canStepUp, panel, visibleMonth } = calendar

const showPanelFor = (kind: SegmentKind) => {
  if (TIME_KINDS.has(kind)) calendar.showTimePanel()
  else calendar.showDatePanel()
}

defineExpose({ focusActive, showPanelFor })

const headingClasses =
  'cursor-default text-xs font-bold text-stone-200 uppercase dark:text-neutral-500'

// The cursor marks the cell the keyboard moved to, which Enter will pick. A pointer takes over
// from there, so it goes again on the next click.
const keyboardCursor = ref(false)

const interactiveClasses =
  'hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline-0 focus:hover:outline-1 focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:hover:outline-blue-900'

const cellClasses = (date: Date, inMonth = true) => {
  let color = 'text-contrast'

  if (isSelected(date)) color = 'bg-blue-800 text-white'
  else if (!inMonth) color = 'text-stone-200 dark:text-neutral-500'
  else if (panel.value === 'day' && isToday(date)) color = 'text-blue-800'

  return [
    'flex items-center justify-center rounded-md text-xs aria-disabled:cursor-not-allowed aria-disabled:opacity-30',
    interactiveClasses,
    panel.value === 'day' ? 'size-6' : 'h-8 w-full px-2',
    color,
    { 'outline-1 outline-offset-1 outline-blue-800': keyboardCursor.value && isFocused(date) },
  ]
}

const onGridKeydown = (event: KeyboardEvent) => {
  if (moveGridFocus(event)) keyboardCursor.value = true
}

const onPointerDown = () => {
  keyboardCursor.value = false
}

const hoursInput = useTemplateRef('hours-input')
const minutesInput = useTemplateRef('minutes-input')

const hoursSpec = computed(() => timeSegmentSpec('hour', props.is24))
const minutesSpec = computed(() => timeSegmentSpec('minute', props.is24))

const hours = useTimeFieldEntry({
  el: hoursInput,
  spec: hoursSpec,
  display: hoursDisplay,
  apply: commitDisplayHour,
  onComplete: () => minutesInput.value?.focus(),
  onMove: (direction) => {
    if (direction > 0) minutesInput.value?.focus()
  },
})

const minutes = useTimeFieldEntry({
  el: minutesInput,
  spec: minutesSpec,
  display: minutesDisplay,
  apply: (value) => commitTime(timeBase.value.getHours(), value),
  onMove: (direction) => {
    if (direction < 0) hoursInput.value?.focus()
  },
})

const finishAndClose = (field: typeof hours) => {
  field.finish()
  emit('done')
}

const navigationButtonClasses = [
  'flex size-6 shrink-0 items-center justify-center rounded-md text-blue-800',
  interactiveClasses,
]

const timeInputClasses =
  'w-16 rounded-md bg-blue-200 px-2 py-1 text-center text-sm text-contrast tabular-nums focus:outline-1 focus:-outline-offset-1 focus:outline-blue-800 dark:bg-gray-700'
</script>

<template>
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
  <div ref="container" class="flex flex-col gap-2 p-2 text-sm" @pointerdown="onPointerDown">
    <div class="flex items-center justify-between gap-1">
      <button
        v-if="panel !== 'time'"
        v-tooltip="prevLabel"
        type="button"
        :class="navigationButtonClasses"
        @click="calendar.prev()"
      >
        <CommonIcon name="chevron-left" size="xs" decorative />
      </button>
      <button
        type="button"
        class="h-6 grow rounded-md px-2 text-sm font-medium text-contrast disabled:hover:outline-0"
        :class="interactiveClasses"
        :aria-label="titleLabel"
        :disabled="!canStepUp"
        @click="calendar.stepUp()"
      >
        {{ title }}
      </button>
      <button
        v-if="panel !== 'time'"
        v-tooltip="nextLabel"
        type="button"
        :class="navigationButtonClasses"
        @click="calendar.next()"
      >
        <CommonIcon name="chevron-right" size="xs" decorative />
      </button>
    </div>

    <div v-if="panel === 'day'" class="flex justify-center">
      <FieldDateGrid
        :rows="weeks"
        :label="fmt(visibleMonth, MONTH_TITLE_FORMAT)"
        table-class="border-separate border-spacing-x-1.5 border-spacing-y-1"
        :column-headers="weekdayHeaders"
        :heading-class="['size-6', headingClasses]"
        :row-header="showWeekNumbers ? (week) => String(weekNumber(week)) : undefined"
        :row-header-label="$t('Calendar week')"
        :row-header-class="['size-6 pe-1 text-center', headingClasses]"
        :cell-text="(day) => fmt(day, 'd')"
        :cell-label="(day) => fmt(day, 'PPPP')"
        :cell-classes="(day) => cellClasses(day, isSameMonth(day, visibleMonth))"
        :is-selected="isSelected"
        :is-focused="isFocused"
        :is-disabled="calendar.isDisabled"
        @select="calendar.select"
        @keydown="onGridKeydown"
      />
    </div>

    <FieldDateGrid
      v-else-if="panel === 'month'"
      :rows="monthRows"
      :label="$t('The month picker')"
      :cell-text="(month) => fmt(month, MONTH_CELL_FORMAT)"
      :cell-label="(month) => fmt(month, MONTH_TITLE_FORMAT)"
      :cell-classes="cellClasses"
      :is-selected="isSelected"
      :is-focused="isFocused"
      :is-disabled="calendar.isDisabled"
      @select="calendar.select"
      @keydown="onGridKeydown"
    />

    <FieldDateGrid
      v-else-if="panel === 'year'"
      :rows="yearRows"
      :label="$t('The year picker')"
      :cell-text="(year) => fmt(year, YEAR_FORMAT)"
      :cell-classes="cellClasses"
      :is-selected="isSelected"
      :is-focused="isFocused"
      :is-disabled="calendar.isDisabled"
      @select="calendar.select"
      @keydown="onGridKeydown"
    />

    <div v-else class="flex flex-col items-center gap-3 py-1">
      <div class="flex items-center gap-1.5">
        <input
          ref="hours-input"
          :value="hours.draft.value"
          :aria-label="$t('Hours')"
          type="text"
          role="spinbutton"
          inputmode="numeric"
          autocomplete="off"
          spellcheck="false"
          :aria-valuemin="hoursSpec.min"
          :aria-valuemax="hoursSpec.max"
          :aria-valuenow="hours.valueNow.value"
          data-focus-target="true"
          :class="timeInputClasses"
          @keydown="hours.onKeydown"
          @keydown.enter.exact.prevent="finishAndClose(hours)"
          @beforeinput="hours.onBeforeInput"
          @paste="hours.onPaste"
          @mousedown="hours.onMousedown"
          @click="hours.onClick"
          @focus="hours.onFocus"
          @blur="hours.onBlur"
        />
        <span aria-hidden="true">:</span>
        <input
          ref="minutes-input"
          :value="minutes.draft.value"
          :aria-label="$t('Minutes')"
          type="text"
          role="spinbutton"
          inputmode="numeric"
          autocomplete="off"
          spellcheck="false"
          :aria-valuemin="minutesSpec.min"
          :aria-valuemax="minutesSpec.max"
          :aria-valuenow="minutes.valueNow.value"
          :class="timeInputClasses"
          @keydown="minutes.onKeydown"
          @keydown.enter.exact.prevent="finishAndClose(minutes)"
          @beforeinput="minutes.onBeforeInput"
          @paste="minutes.onPaste"
          @mousedown="minutes.onMousedown"
          @click="minutes.onClick"
          @focus="minutes.onFocus"
          @blur="minutes.onBlur"
        />
        <button
          v-if="!is24"
          v-tooltip="$t('Toggle AM/PM mode')"
          type="button"
          class="h-8 rounded-md px-2 text-sm text-contrast uppercase"
          :class="interactiveClasses"
          @click="toggleMeridiem"
        >
          {{ fmt(timeBase, 'a') }}
        </button>
      </div>
      <CommonButton variant="primary" size="small" class="self-end" @click="emit('done')">
        {{ $t('Done') }}
      </CommonButton>
    </div>

    <CommonButton
      v-if="panel !== 'time'"
      variant="tertiary"
      size="small"
      block
      :disabled="calendar.isTodayDisabled.value"
      @click="calendar.selectToday()"
    >
      {{ $t('Today') }}
    </CommonButton>
  </div>
</template>
