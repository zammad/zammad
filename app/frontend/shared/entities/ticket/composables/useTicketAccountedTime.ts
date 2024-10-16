// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

export const useTicketAccountedTime = () => {
  const { config: applicationConfig } = storeToRefs(useApplicationStore())

  const timeAccountingConfig = computed(() => ({
    time_accounting_types: applicationConfig.value.time_accounting_types,
    time_accounting_unit: applicationConfig.value.time_accounting_unit,
    time_accounting_unit_custom:
      applicationConfig.value.time_accounting_unit_custom,
  }))

  const timeAccountingDisplayUnit = computed(() => {
    switch (timeAccountingConfig.value.time_accounting_unit) {
      case 'hour':
        return __('hour(s)')
      case 'quarter':
        return __('quarter-hour(s)')
      case 'minute':
        return __('minute(s)')
      case 'custom':
        return timeAccountingConfig.value.time_accounting_unit_custom
      default:
        return ''
    }
  })

  return { timeAccountingDisplayUnit, timeAccountingConfig }
}
