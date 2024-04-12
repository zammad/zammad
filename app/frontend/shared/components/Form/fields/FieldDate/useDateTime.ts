// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
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
    toggleOverlay: i18n.t('Toggle overlay'),
    menu: i18n.t('Datepicker menu'),
    input: i18n.t('Datepicker input'),
    calendarWrap: i18n.t('Calendar wrapper'),
    calendarDays: i18n.t('Calendar days'),
    openTimePicker: i18n.t('Open time picker'),
    closeTimePicker: i18n.t('Close time picker'),
    incrementValue: (type: string) => {
      switch (type) {
        case 'hours':
          return i18n.t('Increment hours')
        case 'minutes':
          return i18n.t('Increment minutes')
        case 'seconds':
        default:
          return i18n.t('Increment seconds')
      }
    },
    decrementValue: (type: string) => {
      switch (type) {
        case 'hours':
          return i18n.t('Decrement hours')
        case 'minutes':
          return i18n.t('Decrement minutes')
        case 'seconds':
        default:
          return i18n.t('Decrement seconds')
      }
    },
    openTpOverlay: (type: string) => {
      switch (type) {
        case 'hours':
          return i18n.t('Open hours overlay')
        case 'minutes':
          return i18n.t('Open minutes overlay')
        case 'seconds':
        default:
          return i18n.t('Open seconds overlay')
      }
    },
    amPmButton: i18n.t('Switch AM/PM mode'),
    openYearsOverlay: i18n.t('Open years overlay'),
    openMonthsOverlay: i18n.t('Open months overlay'),
    nextMonth: i18n.t('Next month'),
    prevMonth: i18n.t('Previous month'),
    nextYear: i18n.t('Next year'),
    prevYear: i18n.t('Previous year'),
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
