<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isSameMonth, isToday } from 'date-fns'
import { computed, ref, useTemplateRef, watch } from 'vue'

import FieldDateGrid from '#shared/components/Form/fields/FieldDate/FieldDateGrid.vue'
import {
  MONTH_CELL_FORMAT,
  MONTH_TITLE_FORMAT,
  padTime,
  useCalendarPanel,
  weekNumber,
  YEAR_FORMAT,
  type CalendarPanelProps,
} from '#shared/components/Form/fields/FieldDate/useCalendarPanel.ts'
import { i18n } from '#shared/i18n.ts'

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
  containsFocus,
  fmt,
  focusActive,
  hoursDisplay,
  isFocused,
  isSelected,
  minutesDisplay,
  monthRows,
  nextLabel,
  onGridKeydown,
  prevLabel,
  timeBase,
  title: panelTitle,
  titleLabel: panelTitleLabel,
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

// The time view offers the hours and the minutes as a grid as well, one at a time.
type TimeGrid = 'hours' | 'minutes'

const timeGrid = ref<TimeGrid | undefined>()

// The value the last grid was opened from takes the focus back once the grid closes.
const focusedTime = ref<TimeGrid>('hours')

const openGrid = (grid: TimeGrid) => {
  focusedTime.value = grid
  timeGrid.value = grid
}

watch(panel, () => {
  timeGrid.value = undefined
})

// The grid takes the place of the steppers, and the value it opened from goes with them.
watch(timeGrid, () => {
  if (containsFocus()) focusActive()
})

const timeDisplay = computed(() => {
  const time = `${hoursDisplay.value}:${minutesDisplay.value}`

  return props.is24 ? time : `${time} ${fmt(timeBase.value, 'a')}`
})

const title = computed(() => (timeGrid.value ? timeDisplay.value : panelTitle.value))

const titleLabel = computed(() =>
  timeGrid.value ? i18n.t('Back to the time picker') : panelTitleLabel.value,
)

const onTitleClick = () => {
  if (timeGrid.value) {
    timeGrid.value = undefined
    return
  }

  calendar.stepUp()
}

const canNavigateTitle = computed(() => canStepUp.value || Boolean(timeGrid.value))

const cellClasses = (date: Date, inMonth = true) => {
  let color = 'text-white'

  if (isSelected(date)) color = 'bg-blue text-white'
  else if (!inMonth) color = 'text-gray'
  else if (panel.value === 'day' && isToday(date)) color = 'text-blue'

  return [
    'flex items-center justify-center text-base aria-disabled:opacity-30',
    panel.value === 'day' ? 'mx-auto size-9 rounded-full' : 'h-10 w-full rounded-xl px-2',
    color,
  ]
}

const stepHours = (delta: 1 | -1) => {
  commitTime((timeBase.value.getHours() + delta + 24) % 24, timeBase.value.getMinutes())
}

const stepMinutes = (delta: 1 | -1) => {
  commitTime(timeBase.value.getHours(), (timeBase.value.getMinutes() + delta + 60) % 60)
}

const hourOptions = computed(() =>
  props.is24
    ? Array.from({ length: 24 }, (_, hour) => hour)
    : Array.from({ length: 12 }, (_, index) => index + 1),
)

const MINUTE_STEP = 5

const minuteOptions = Array.from({ length: 60 / MINUTE_STEP }, (_, index) => index * MINUTE_STEP)

const pickHour = (hour: number) => {
  commitDisplayHour(hour)
  timeGrid.value = undefined
}

const pickMinute = (minute: number) => {
  commitTime(timeBase.value.getHours(), minute)
  timeGrid.value = undefined
}

const isCurrentHour = (hour: number) => padTime(hour) === hoursDisplay.value

const isCurrentMinute = (minute: number) => minute === timeBase.value.getMinutes()

// A time off the raster of the grid lands the focus on the option just before it.
const isNearestMinute = (minute: number) =>
  minute === Math.floor(timeBase.value.getMinutes() / MINUTE_STEP) * MINUTE_STEP

const timeOptionClasses = (current: boolean) => [
  'flex h-12 items-center justify-center rounded-xl text-base',
  current ? 'bg-blue text-white' : 'text-white',
]

const headingClasses = 'h-8 text-center text-sm font-semibold text-gray uppercase'

const navigationButtonClasses = 'flex size-10 shrink-0 items-center justify-center text-blue'

const stepButtonClasses = 'flex size-10 items-center justify-center text-gray'

const timeValueButtonClasses =
  'flex h-10 min-w-10 items-center justify-center px-1 text-lg text-white'

const actionButtonClasses = 'h-10 w-60 self-center rounded-xl text-base text-white'
</script>

<template>
  <div ref="container" class="flex flex-col gap-2 px-2 py-3">
    <div class="flex items-center justify-between">
      <button
        v-if="panel !== 'time'"
        type="button"
        :class="navigationButtonClasses"
        :aria-label="prevLabel"
        @click="calendar.prev()"
      >
        <CommonIcon name="chevron-left" size="small" decorative />
      </button>
      <button
        type="button"
        class="h-10 grow rounded-xl px-2 text-base font-semibold text-white disabled:opacity-100"
        :aria-label="titleLabel"
        :disabled="!canNavigateTitle"
        @click="onTitleClick"
      >
        {{ title }}
      </button>
      <button
        v-if="panel !== 'time'"
        type="button"
        :class="navigationButtonClasses"
        :aria-label="nextLabel"
        @click="calendar.next()"
      >
        <CommonIcon name="chevron-right" size="small" decorative />
      </button>
    </div>

    <FieldDateGrid
      v-if="panel === 'day'"
      :rows="weeks"
      :label="fmt(visibleMonth, MONTH_TITLE_FORMAT)"
      table-class="w-full border-separate border-spacing-y-1"
      :column-headers="weekdayHeaders"
      :heading-class="headingClasses"
      :row-header="showWeekNumbers ? (week) => String(weekNumber(week)) : undefined"
      :row-header-label="$t('Calendar week')"
      row-header-class="text-center text-sm text-gray"
      :cell-text="(day) => fmt(day, 'd')"
      :cell-label="(day) => fmt(day, 'PPPP')"
      :cell-classes="(day) => cellClasses(day, isSameMonth(day, visibleMonth))"
      :is-selected="isSelected"
      :is-focused="isFocused"
      :is-disabled="calendar.isDisabled"
      @select="calendar.select"
      @keydown="onGridKeydown"
    />

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

    <div
      v-else-if="timeGrid === 'hours'"
      role="listbox"
      :aria-label="$t('The hours overlay')"
      class="grid max-h-72 grid-cols-3 gap-1 overflow-y-auto"
    >
      <button
        v-for="hour in hourOptions"
        :key="hour"
        type="button"
        role="option"
        :aria-selected="isCurrentHour(hour)"
        :data-focus-target="isCurrentHour(hour) || undefined"
        :class="timeOptionClasses(isCurrentHour(hour))"
        @click="pickHour(hour)"
      >
        {{ padTime(hour) }}
      </button>
    </div>

    <div
      v-else-if="timeGrid === 'minutes'"
      role="listbox"
      :aria-label="$t('The minutes overlay')"
      class="grid max-h-72 grid-cols-3 gap-1 overflow-y-auto"
    >
      <button
        v-for="minute in minuteOptions"
        :key="minute"
        type="button"
        role="option"
        :aria-selected="isCurrentMinute(minute)"
        :data-focus-target="isNearestMinute(minute) || undefined"
        :class="timeOptionClasses(isCurrentMinute(minute))"
        @click="pickMinute(minute)"
      >
        {{ padTime(minute) }}
      </button>
    </div>

    <div v-else class="flex items-center justify-center gap-4 py-6">
      <div class="flex flex-col items-center">
        <button
          type="button"
          :class="stepButtonClasses"
          :aria-label="$t('Increment hours value')"
          @click="stepHours(1)"
        >
          <CommonIcon name="chevron-up" size="tiny" decorative />
        </button>
        <button
          type="button"
          :class="timeValueButtonClasses"
          :aria-label="$t('Open the hours overlay')"
          :data-focus-target="focusedTime === 'hours' || undefined"
          @click="openGrid('hours')"
        >
          {{ hoursDisplay }}
        </button>
        <button
          type="button"
          :class="stepButtonClasses"
          :aria-label="$t('Decrement hours value')"
          @click="stepHours(-1)"
        >
          <CommonIcon name="chevron-down" size="tiny" decorative />
        </button>
      </div>
      <span class="text-lg text-white" aria-hidden="true">:</span>
      <div class="flex flex-col items-center">
        <button
          type="button"
          :class="stepButtonClasses"
          :aria-label="$t('Increment minutes value')"
          @click="stepMinutes(1)"
        >
          <CommonIcon name="chevron-up" size="tiny" decorative />
        </button>
        <button
          type="button"
          :class="timeValueButtonClasses"
          :aria-label="$t('Open the minutes overlay')"
          :data-focus-target="focusedTime === 'minutes' || undefined"
          @click="openGrid('minutes')"
        >
          {{ minutesDisplay }}
        </button>
        <button
          type="button"
          :class="stepButtonClasses"
          :aria-label="$t('Decrement minutes value')"
          @click="stepMinutes(-1)"
        >
          <CommonIcon name="chevron-down" size="tiny" decorative />
        </button>
      </div>
      <button
        v-if="!is24"
        type="button"
        class="h-10 rounded-xl px-2 text-lg text-white uppercase"
        :aria-label="$t('Toggle AM/PM mode')"
        @click="toggleMeridiem"
      >
        {{ fmt(timeBase, 'a') }}
      </button>
    </div>

    <button
      v-if="panel === 'time'"
      type="button"
      :class="[actionButtonClasses, 'bg-blue']"
      @click="emit('done')"
    >
      {{ $t('Done') }}
    </button>
    <button
      v-else
      type="button"
      :class="[actionButtonClasses, 'bg-gray-200 disabled:opacity-30']"
      :disabled="calendar.isTodayDisabled.value"
      @click="calendar.selectToday()"
    >
      {{ $t('Today') }}
    </button>
  </div>
</template>
