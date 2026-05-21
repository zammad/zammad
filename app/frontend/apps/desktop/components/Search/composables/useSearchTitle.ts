// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { type Ref } from 'vue'

import { i18n } from '#shared/i18n.ts'

export const useSearchTitle = (currentSearchTerm: Ref<string>, filterCount: Ref<number>) => {
  const searchTitle = computed(() => {
    const currentFiltersString = filterCount.value ? i18n.t('%s filter(s)', filterCount.value) : ''
    const parts = [currentSearchTerm.value, currentFiltersString].filter(Boolean)

    return parts.join(' + ') || i18n.t('Extended search')
  })

  return { searchTitle }
}
