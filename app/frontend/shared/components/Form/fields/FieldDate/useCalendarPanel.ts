// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  format,
  getISOWeek,
  isSameDay,
  isSameMonth,
  isSameYear,
  setHours,
  setMinutes,
} from 'date-fns'
import { chunk } from 'lodash-es'
import { computed, nextTick, toRef, watch, type Ref } from 'vue'

import { i18n } from '#shared/i18n.ts'
import stopEvent from '#shared/utils/events.ts'

import { mergeTime, useCalendar, type CalendarBounds } from './useCalendar.ts'

import type { DateWeekStart, TimeOfDay } from './types.ts'
import type { Locale } from 'date-fns'

export interface CalendarPanelProps {
  selected?: Date
  bounds: CalendarBounds
  // Adds the time panel after a day is picked.
  withTime: boolean
  defaultTime?: TimeOfDay
  weekStart: DateWeekStart
  locale?: Locale
  is24: boolean
}

export interface UseCalendarPanelOptions {
  container: Ref<HTMLElement | null>
  onCommit: (date: Date) => void
  onDone: () => void
}

/* eslint-disable zammad/zammad-detect-translatable-string */
export const MONTH_TITLE_FORMAT = 'LLLL yyyy'

// The labels of the month, weekday and year cells.
export const MONTH_CELL_FORMAT = 'MMM'
const WEEKDAY_FORMAT = 'EEEEEE'
export const YEAR_FORMAT = 'yyyy'
/* eslint-enable zammad/zammad-detect-translatable-string */

export const padTime = (value: number) => String(value).padStart(2, '0')

// The ISO week of the row's fourth day: that day lies in the same ISO week whether the row
// starts on a Monday or on a Sunday.
export const weekNumber = (week: Date[]) => getISOWeek(week[3])

// What a calendar panel shows on top of the calendar state, shared by the desktop and the
// mobile panel: the header, the state of each cell and the time the time view works on.
export const useCalendarPanel = (props: CalendarPanelProps, options: UseCalendarPanelOptions) => {
  const calendar = useCalendar({
    selected: toRef(props, 'selected'),
    bounds: toRef(props, 'bounds'),
    withTime: toRef(props, 'withTime'),
    weekStart: toRef(props, 'weekStart'),
    defaultTime: toRef(props, 'defaultTime'),
    onCommit: options.onCommit,
    onDone: options.onDone,
  })

  const { focusedDate, months, panel, visibleMonth, years } = calendar

  const focusActive = () => {
    nextTick(() => {
      options.container.value?.querySelector<HTMLElement>('[data-focus-target="true"]')?.focus()
    })
  }

  const containsFocus = () => Boolean(options.container.value?.contains(document.activeElement))

  // The cell that held the focus leaves the DOM together with its panel.
  watch(panel, () => {
    if (containsFocus()) focusActive()
  })

  const fmt = (date: Date, pattern: string) => format(date, pattern, { locale: props.locale })

  const monthRows = computed(() => chunk(months.value, 3))

  const yearRows = computed(() => chunk(years.value, 5))

  const weeks = computed(() => calendar.weeksOf(visibleMonth.value))

  const weekdayHeaders = computed(() =>
    weeks.value[0].map((day) => ({
      key: day.toISOString(),
      text: fmt(day, WEEKDAY_FORMAT),
      label: fmt(day, 'EEEE'),
    })),
  )

  const timeBase = computed(
    () => props.selected ?? mergeTime(focusedDate.value, undefined, props.defaultTime),
  )

  const title = computed(() => {
    switch (panel.value) {
      case 'year':
        return `${fmt(years.value[0], YEAR_FORMAT)} – ${fmt(years.value[9], YEAR_FORMAT)}`
      case 'month':
        return fmt(focusedDate.value, YEAR_FORMAT)
      case 'time':
        return fmt(timeBase.value, 'PPP')
      default:
        return fmt(visibleMonth.value, MONTH_TITLE_FORMAT)
    }
  })

  const titleLabel = computed(() => {
    switch (panel.value) {
      case 'day':
        return i18n.t('Open the months overlay')
      case 'month':
        return i18n.t('Open the years overlay')
      case 'time':
        return i18n.t('Back to the calendar')
      default:
        return undefined
    }
  })

  const prevLabel = computed(() => {
    switch (panel.value) {
      case 'month':
        return i18n.t('Previous year')
      case 'year':
        return i18n.t('Previous decade')
      default:
        return i18n.t('Previous month')
    }
  })

  const nextLabel = computed(() => {
    switch (panel.value) {
      case 'month':
        return i18n.t('Next year')
      case 'year':
        return i18n.t('Next decade')
      default:
        return i18n.t('Next month')
    }
  })

  const isSelected = (date: Date) => {
    if (!props.selected) return false
    if (panel.value === 'month') return isSameMonth(date, props.selected)
    if (panel.value === 'year') return isSameYear(date, props.selected)

    return isSameDay(date, props.selected)
  }

  const isFocused = (date: Date) => {
    if (panel.value === 'month') return isSameMonth(date, focusedDate.value)
    if (panel.value === 'year') return isSameYear(date, focusedDate.value)

    return isSameDay(date, focusedDate.value)
  }

  // Moves the keyboard focus within the grid, returns whether the key was handled.
  const onGridKeydown = (event: KeyboardEvent) => {
    if (!calendar.moveFocus(event)) return false

    stopEvent(event)
    focusActive()

    return true
  }

  const isAfternoon = computed(() => timeBase.value.getHours() >= 12)

  const hoursDisplay = computed(() => {
    const hours = timeBase.value.getHours()

    if (props.is24) return padTime(hours)

    return padTime(hours % 12 || 12)
  })

  const minutesDisplay = computed(() => padTime(timeBase.value.getMinutes()))

  const commitTime = (hours: number, minutes: number) => {
    options.onCommit(setMinutes(setHours(timeBase.value, hours), minutes))
  }

  const toggleMeridiem = () => {
    commitTime((timeBase.value.getHours() + 12) % 24, timeBase.value.getMinutes())
  }

  // Takes the hour as shown, so on a 12-hour clock it keeps the current half of the day.
  const commitDisplayHour = (hour: number) => {
    const hours = props.is24 ? hour : (hour % 12) + (isAfternoon.value ? 12 : 0)

    commitTime(hours, timeBase.value.getMinutes())
  }

  return {
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
    title,
    titleLabel,
    toggleMeridiem,
    weekdayHeaders,
    weeks,
    yearRows,
  }
}
