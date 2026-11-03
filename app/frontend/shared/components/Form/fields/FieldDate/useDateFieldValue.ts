// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { endOfDay, format, isValid, parse, parseISO } from 'date-fns'
import { computed, ref, type Ref } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { formatDateTimeValue } from '#shared/components/Form/fields/FieldDate/normalizeDateValue.ts'
import { useDateFnsLocale } from '#shared/components/Form/fields/FieldDate/useDateFnsLocale.ts'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { toDate, type CalendarBounds } from './useCalendar.ts'

import type { DateFieldContext } from './types.ts'

// The value side of a datepicker field, shared by the desktop and the mobile input: the panels
// the field walks through, the bounds, the value format and the date the value stands for.
export const useDateFieldValue = (context: Ref<DateFieldContext>) => {
  const { hasValue, localValue, clearValue } = useValue<string | null>(context)

  const timePicker = computed(() => context.value.type === 'datetime')

  const valueFormat = computed(() => (timePicker.value ? 'iso' : 'yyyy-MM-dd'))

  // Refreshed on every open and commit, else a future-only field mounted before 08:00 accepts
  // today 08:00 once it has passed.
  const now = ref(new Date())

  const refreshNow = () => {
    now.value = new Date()
  }

  const maxDate = computed(() => (context.value.pastOnly ? now.value : context.value.maxDate))

  const minDate = computed(() => (context.value.futureOnly ? now.value : context.value.minDate))

  const is24 = computed(() => i18n.getTimeFormatType() === '24hour')

  // The locale's format in Zammad's own tokens.
  const localeFormat = computed(() => {
    if (timePicker.value) return i18n.getDateTimeFormat()
    return i18n.getDateFormat()
  })

  const { dateFnsLocale } = useDateFnsLocale()

  const application = useApplicationStore()

  const showWeekNumbers = computed(() => Boolean(application.config.datepicker_show_calendar_weeks))

  const bounds = computed<CalendarBounds>(() => ({
    minDate: minDate.value,
    maxDate: maxDate.value,
    disabledDays: context.value.disabledDays,
  }))

  const parseValue = (value: string) => {
    if (valueFormat.value === 'iso') return parseISO(value)
    return parse(value, valueFormat.value, new Date())
  }

  const formatValue = (date: Date) => {
    if (valueFormat.value === 'iso') return formatDateTimeValue(date)
    return format(date, valueFormat.value)
  }

  const selectedDate = computed(() => {
    const { value } = localValue

    if (typeof value !== 'string' || !value) return undefined

    const date = parseValue(value)

    return isValid(date) ? date : undefined
  })

  const isDateOnly = (value?: Date | string) => typeof value === 'string' && !value.includes('T')

  // The morning default of a picked or typed date is kept inside the bounds, so a `futureOnly`
  // field set to today still gets a value: the earliest allowed instant.
  const commit = (date: Date) => {
    refreshNow()

    const min = toDate(minDate.value)
    let max = toDate(maxDate.value)

    // A maximum without a time includes its whole day, like in the calendar.
    if (max && isDateOnly(maxDate.value)) max = endOfDay(max)

    let result = date
    if (min && result < min) result = min
    if (max && result > max) result = max

    const value = formatValue(result)
    if (value !== localValue.value) localValue.value = value
  }

  return {
    bounds,
    clearValue,
    commit,
    dateFnsLocale,
    hasValue,
    is24,
    localValue,
    localeFormat,
    refreshNow,
    selectedDate,
    showWeekNumbers,
    timePicker,
  }
}
