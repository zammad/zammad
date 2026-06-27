// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import type { ConfigList } from '#shared/types/config.ts'

// Pure config → display-unit mapping, shared by the composable and other
// config-driven consumers (e.g. the search filter override). Returns an
// untranslated key — translation happens at the label/display output.
export const getTimeAccountingDisplayUnit = (
  config: Pick<ConfigList, 'time_accounting_unit' | 'time_accounting_unit_custom'>,
): string => {
  switch (config.time_accounting_unit) {
    case 'hour':
      return __('hour(s)')
    case 'quarter':
      return __('quarter-hour(s)')
    case 'minute':
      return __('minute(s)')
    case 'custom':
      return config.time_accounting_unit_custom
    default:
      return ''
  }
}

export const useTicketAccountedTime = () => {
  const applicationConfig = toRef(useApplicationStore(), 'config')

  const timeAccountingConfig = computed(() => ({
    time_accounting_types: applicationConfig.value.time_accounting_types,
    time_accounting_unit: applicationConfig.value.time_accounting_unit,
    time_accounting_unit_custom: applicationConfig.value.time_accounting_unit_custom,
  }))

  const timeAccountingDisplayUnit = computed(() =>
    getTimeAccountingDisplayUnit(applicationConfig.value),
  )

  return { timeAccountingDisplayUnit, timeAccountingConfig }
}
