// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  addDays,
  addMonths,
  addYears,
  endOfDay,
  endOfMonth,
  endOfWeek,
  endOfYear,
  getDaysInMonth,
  isAfter,
  isBefore,
  isValid,
  parseISO,
  startOfDay,
  startOfMonth,
  startOfWeek,
  startOfYear,
} from 'date-fns'
import { computed, ref, watch, type Ref } from 'vue'

import type { DatePanel, DateWeekStart, TimeOfDay } from './types.ts'

export interface CalendarBounds {
  minDate?: Date | string
  maxDate?: Date | string
  disabledDays?: (date: Date) => boolean
}

export interface UseCalendarOptions {
  selected: Ref<Date | undefined>
  bounds: Ref<CalendarBounds>
  // Adds the time panel after a day is picked.
  withTime: Ref<boolean>
  weekStart: Ref<DateWeekStart>
  defaultTime?: Ref<TimeOfDay | undefined>
  onCommit: (date: Date) => void
  onDone: () => void
}

type KeyPress = Pick<KeyboardEvent, 'key' | 'shiftKey'>

// A picked date starts in the morning, like in the legacy UI.
export const DEFAULT_TIME: TimeOfDay = { hours: 8, minutes: 0 }

export const toDate = (value?: Date | string | null) => {
  if (!value) return undefined

  const date = value instanceof Date ? value : parseISO(value)

  return isValid(date) ? date : undefined
}

export const buildMonthWeeks = (month: Date, weekStart: DateWeekStart) => {
  const options = { weekStartsOn: weekStart }
  const last = endOfWeek(endOfMonth(month), options)
  const weeks: Date[][] = []

  for (let day = startOfWeek(startOfMonth(month), options); day <= last; day = addDays(day, 7)) {
    weeks.push(Array.from({ length: 7 }, (_, offset) => addDays(day, offset)))
  }

  return weeks
}

const buildMonths = (year: Date) =>
  Array.from({ length: 12 }, (_, month) => new Date(year.getFullYear(), month, 1))

const decadeStart = (date: Date) => Math.floor(date.getFullYear() / 10) * 10

export const buildDecadeYears = (date: Date) => {
  const start = decadeStart(date)

  return Array.from({ length: 10 }, (_, offset) => new Date(start + offset, 0, 1))
}

const isOutsideBounds = (start: Date, end: Date, bounds: CalendarBounds) => {
  const min = toDate(bounds.minDate)
  const max = toDate(bounds.maxDate)

  return Boolean((min && isBefore(end, startOfDay(min))) || (max && isAfter(start, endOfDay(max))))
}

// Without a selection the calendar opens on today, or on the nearest bound when today lies
// outside of them: the end of a range that starts next year opens on that start.
const initialFocus = (selected: Date | undefined, bounds: CalendarBounds) => {
  if (selected) return startOfDay(selected)

  const today = startOfDay(new Date())
  const min = toDate(bounds.minDate)
  const max = toDate(bounds.maxDate)

  if (min && isBefore(today, startOfDay(min))) return startOfDay(min)
  if (max && isAfter(today, endOfDay(max))) return startOfDay(max)

  return today
}

export const isDayDisabled = (date: Date, bounds: CalendarBounds) =>
  isOutsideBounds(date, date, bounds) || Boolean(bounds.disabledDays?.(date))

// A month or year stays enabled as long as one of its days lies within the bounds.
export const isMonthDisabled = (month: Date, bounds: CalendarBounds) =>
  isOutsideBounds(startOfMonth(month), endOfMonth(month), bounds)

export const isYearDisabled = (year: Date, bounds: CalendarBounds) =>
  isOutsideBounds(startOfYear(year), endOfYear(year), bounds)

// Keeps the day of the month where the target month has it, otherwise its last day.
const moveToMonth = (date: Date, year: number, month: number) =>
  new Date(year, month, Math.min(date.getDate(), getDaysInMonth(new Date(year, month, 1))))

export const mergeTime = (date: Date, source?: Date, defaultTime = DEFAULT_TIME) => {
  const result = startOfDay(date)

  result.setHours(
    source?.getHours() ?? defaultTime.hours,
    source?.getMinutes() ?? defaultTime.minutes,
  )

  return result
}

const moveDay = (date: Date, { key, shiftKey }: KeyPress, weekStart: DateWeekStart) => {
  switch (key) {
    case 'ArrowLeft':
      return addDays(date, -1)
    case 'ArrowRight':
      return addDays(date, 1)
    case 'ArrowUp':
      return addDays(date, -7)
    case 'ArrowDown':
      return addDays(date, 7)
    case 'Home':
      return startOfWeek(date, { weekStartsOn: weekStart })
    case 'End':
      return startOfDay(endOfWeek(date, { weekStartsOn: weekStart }))
    case 'PageUp':
      return shiftKey ? addYears(date, -1) : addMonths(date, -1)
    case 'PageDown':
      return shiftKey ? addYears(date, 1) : addMonths(date, 1)
    default:
      return undefined
  }
}

const moveMonth = (date: Date, { key }: KeyPress) => {
  switch (key) {
    case 'ArrowLeft':
      return addMonths(date, -1)
    case 'ArrowRight':
      return addMonths(date, 1)
    case 'ArrowUp':
      return addMonths(date, -3)
    case 'ArrowDown':
      return addMonths(date, 3)
    case 'Home':
      return moveToMonth(date, date.getFullYear(), 0)
    case 'End':
      return moveToMonth(date, date.getFullYear(), 11)
    case 'PageUp':
      return addYears(date, -1)
    case 'PageDown':
      return addYears(date, 1)
    default:
      return undefined
  }
}

const moveYear = (date: Date, { key }: KeyPress) => {
  switch (key) {
    case 'ArrowLeft':
      return addYears(date, -1)
    case 'ArrowRight':
      return addYears(date, 1)
    case 'ArrowUp':
      return addYears(date, -5)
    case 'ArrowDown':
      return addYears(date, 5)
    case 'Home':
      return moveToMonth(date, decadeStart(date), date.getMonth())
    case 'End':
      return moveToMonth(date, decadeStart(date) + 9, date.getMonth())
    case 'PageUp':
      return addYears(date, -10)
    case 'PageDown':
      return addYears(date, 10)
    default:
      return undefined
  }
}

// The state of the calendar panel: which panel is shown and which cell holds the keyboard focus,
// whose month the day panel shows. The month and year panels are reached through the header and
// lead back down to the day panel, where a picked day commits the date.
export const useCalendar = (options: UseCalendarOptions) => {
  const hasTimePanel = options.withTime

  const panel = ref<DatePanel>('day')
  const focusedDate = ref(initialFocus(options.selected.value, options.bounds.value))
  const visibleMonth = computed(() => startOfMonth(focusedDate.value))

  const weeksOf = (month: Date) => buildMonthWeeks(month, options.weekStart.value)

  const months = computed(() => buildMonths(focusedDate.value))

  const years = computed(() => buildDecadeYears(focusedDate.value))

  const canStepUp = computed(() => panel.value !== 'year')

  const isDisabled = (date: Date) => {
    if (panel.value === 'month') return isMonthDisabled(date, options.bounds.value)
    if (panel.value === 'year') return isYearDisabled(date, options.bounds.value)

    return isDayDisabled(date, options.bounds.value)
  }

  // A date typed into the input while the panel is shown alongside brings the view along.
  watch(options.selected, (date) => {
    if (date) focusedDate.value = startOfDay(date)
  })

  const shiftView = (direction: 1 | -1) => {
    if (panel.value === 'day') {
      focusedDate.value = addMonths(focusedDate.value, direction)
    } else if (panel.value === 'month') {
      focusedDate.value = addYears(focusedDate.value, direction)
    } else if (panel.value === 'year') {
      focusedDate.value = addYears(focusedDate.value, direction * 10)
    }
  }

  const next = () => shiftView(1)

  const prev = () => shiftView(-1)

  // Follows the group edited in the input while the panel is shown alongside it.
  const showTimePanel = () => {
    if (hasTimePanel.value) panel.value = 'time'
  }

  const showDatePanel = () => {
    if (panel.value === 'time') panel.value = 'day'
  }

  const stepUp = () => {
    if (panel.value === 'day') panel.value = 'month'
    else if (panel.value === 'month') panel.value = 'year'
    else if (panel.value === 'time') panel.value = 'day'
  }

  const pick = (date: Date) => {
    focusedDate.value = startOfDay(date)
    options.onCommit(
      hasTimePanel.value
        ? mergeTime(date, options.selected.value, options.defaultTime?.value)
        : startOfDay(date),
    )

    if (hasTimePanel.value) panel.value = 'time'
    else options.onDone()
  }

  const select = (date: Date) => {
    if (isDisabled(date)) return

    if (panel.value === 'day') {
      pick(date)
      return
    }

    if (panel.value === 'year') {
      focusedDate.value = moveToMonth(
        focusedDate.value,
        date.getFullYear(),
        focusedDate.value.getMonth(),
      )
      panel.value = 'month'
      return
    }

    focusedDate.value = moveToMonth(focusedDate.value, date.getFullYear(), date.getMonth())
    panel.value = 'day'
  }

  const isTodayDisabled = computed(() =>
    isDayDisabled(startOfDay(new Date()), options.bounds.value),
  )

  // Picks today from any date panel, as if it had been chosen in the final one.
  const selectToday = () => {
    if (isTodayDisabled.value) return

    pick(startOfDay(new Date()))
  }

  const stepCell = (date: Date, direction: 1 | -1) => {
    if (panel.value === 'month') return addMonths(date, direction)
    if (panel.value === 'year') return addYears(date, direction)

    return addDays(date, direction)
  }

  // The keyboard skips disabled cells: from a disabled target it goes on in the same direction
  // until an enabled cell turns up, within a span that covers a year of days.
  const nearestEnabled = (target: Date, direction: 1 | -1) => {
    let candidate = target

    for (let step = 0; step < 400; step += 1) {
      if (!isDisabled(candidate)) return candidate

      candidate = stepCell(candidate, direction)
    }

    return undefined
  }

  // Moves the keyboard focus within the current panel, returns whether the key was handled.
  const moveFocus = (event: KeyPress) => {
    let target: Date | undefined

    if (panel.value === 'day') target = moveDay(focusedDate.value, event, options.weekStart.value)
    else if (panel.value === 'month') target = moveMonth(focusedDate.value, event)
    else if (panel.value === 'year') target = moveYear(focusedDate.value, event)

    if (!target) return false

    const enabled = nearestEnabled(target, target < focusedDate.value ? -1 : 1)

    if (!enabled) return true

    focusedDate.value = enabled

    return true
  }

  return {
    canStepUp,
    focusedDate,
    hasTimePanel,
    isDisabled,
    isTodayDisabled,
    months,
    moveFocus,
    next,
    panel,
    prev,
    select,
    selectToday,
    showDatePanel,
    showTimePanel,
    stepUp,
    visibleMonth,
    weeksOf,
    years,
  }
}
