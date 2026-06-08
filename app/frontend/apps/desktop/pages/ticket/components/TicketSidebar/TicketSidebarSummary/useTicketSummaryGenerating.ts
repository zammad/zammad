// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createGlobalState } from '@vueuse/shared'
import { readonly, shallowRef } from 'vue'

export const useTicketSummaryGenerating = createGlobalState(() => {
  const isSummaryGenerating = shallowRef(false)

  const updateSummaryGenerating = (isGenerating: boolean) => {
    isSummaryGenerating.value = isGenerating
  }
  return {
    isSummaryGenerating: readonly(isSummaryGenerating),
    updateSummaryGenerating,
  }
})
