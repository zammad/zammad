// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import { EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import type { DateTimeContext } from './types.ts'

export const useDateTime = (context: Ref<DateTimeContext>) => {
  const timePicker = computed(() => context.value.type === 'datetime')

  const valueFormat = computed(() => {
    if (timePicker.value) return 'iso'
    return 'yyyy-MM-dd'
  })

  const localeStore = useLocaleStore()

  const position = computed(() =>
    localeStore.localeData?.dir === EnumTextDirection.Rtl ? 'right' : 'left',
  )

  const minDate = computed(() => {
    if (context.value.futureOnly) return new Date()
    return context.value.minDate
  })

  const displayFormat = computed(() => {
    let result = i18n.getDateFormat()

    if (timePicker.value) result = i18n.getDateTimeFormat()

    result = result.replace(/m/g, '{m}')
    result = result.replace(/M/g, 'm')
    result = result.replace(/\{m\}/g, 'M')
    result = result.replace(/l/g, 'h')
    result = result.replace(/P/g, 'aaa')

    return result
  })

  const is24 = computed(() => i18n.getTimeFormatType() === '24hour')

  const ariaLabels = computed(() => ({
    toggleOverlay: i18n.t('Toggle the overlay'),
    menu: i18n.t('Datepicker menu'),
    input: i18n.t('Datepicker input field'),
    openTimePicker: i18n.t('Open the time picker'),
    closeTimePicker: i18n.t('Close the time picker'),
    incrementValue: (type: string) => {
      switch (type) {
        case 'hours':
          return i18n.t('Increment hours value')
        case 'minutes':
          return i18n.t('Increment minutes value')
        case 'seconds':
        default:
          return i18n.t('Increment seconds value')
      }
    },
    decrementValue: (type: string) => {
      switch (type) {
        case 'hours':
          return i18n.t('Decrement hours value')
        case 'minutes':
          return i18n.t('Decrement minutes value')
        case 'seconds':
        default:
          return i18n.t('Decrement seconds value')
      }
    },
    openTpOverlay: (type: string) => {
      switch (type) {
        case 'hours':
          return i18n.t('Open the hours overlay')
        case 'minutes':
          return i18n.t('Open the minutes overlay')
        case 'seconds':
        default:
          return i18n.t('Open the seconds overlay')
      }
    },
    amPmButton: i18n.t('Toggle AM/PM mode'),
    openYearsOverlay: i18n.t('Open the years overlay'),
    openMonthsOverlay: i18n.t('Open the months overlay'),
    nextMonth: i18n.t('Next month'),
    prevMonth: i18n.t('Previous month'),
    nextYear: i18n.t('Next year'),
    prevYear: i18n.t('Previous year'),
    clearInput: i18n.t('Clear the value'),
    calendarIcon: i18n.t('The calendar icon'),
    timePicker: i18n.t('The time picker'),
    monthPicker: (overlay: boolean) =>
      overlay ? i18n.t('The month picker overlay') : i18n.t('The month picker'),
    yearPicker: (overlay: boolean) =>
      overlay ? i18n.t('The year picker overlay') : i18n.t('The year picker'),
    timeOverlay: (type: 'hours' | 'minutes' | 'seconds') => {
      switch (type) {
        case 'hours':
          return i18n.t('The hours overlay')
        case 'minutes':
          return i18n.t('The minutes overlay')
        case 'seconds':
        default:
          return i18n.t('The seconds overlay')
      }
    },
  }))

  return {
    ariaLabels,
    displayFormat,
    is24,
    localeStore,
    minDate,
    position,
    timePicker,
    valueFormat,
  }
}
