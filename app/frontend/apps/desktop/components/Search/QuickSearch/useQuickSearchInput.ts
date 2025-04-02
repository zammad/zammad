// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import emitter from '#shared/utils/emitter.ts'

export const useQuickSearchInput = () => {
  const resetQuickSearchInputField = () => {
    emitter.emit('reset-quick-search-field')
  }

  return {
    resetQuickSearchInputField,
  }
}
