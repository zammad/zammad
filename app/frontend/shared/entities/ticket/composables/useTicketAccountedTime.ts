// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { i18n } from '#shared/i18n.ts'
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

  // The display unit is empty when no unit is configured, in that case only the value is shown.
  const formatAccountedTime = (timeUnit?: number | null) => {
    if (timeUnit == null) return ''

    return [timeUnit.toFixed(2), i18n.t(timeAccountingDisplayUnit.value)].filter(Boolean).join(' ')
  }

  // Activity types are only recorded if the feature is enabled.
  // The label and the activity type are one translatable sentence, so a translation can order
  //   the type relative to the label. The accounted time stays out of it, because the legacy
  //   ticket zoom renders it on a line of its own and shares this string.
  // The sentence is returned untranslated-into-markup so callers can decide how to render it
  //   (e.g. plain markup(), or cleanupMarkup() first for a tooltip).
  const formatAccountedTimeType = (article: Pick<TicketArticle, 'accountedTimeType'>) => {
    if (!timeAccountingConfig.value.time_accounting_types) return undefined

    const activityType = article.accountedTimeType?.name
    if (!activityType) return undefined

    return i18n.t('for activity type |%s|', i18n.t(activityType))
  }

  return {
    timeAccountingDisplayUnit,
    timeAccountingConfig,
    formatAccountedTime,
    formatAccountedTimeType,
  }
}
