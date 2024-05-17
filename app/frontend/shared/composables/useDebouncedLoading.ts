// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { refDebounced } from '@vueuse/shared'
import { ref } from 'vue'

export const useDebouncedLoading = (ms = 300) => {
  const loading = ref(false)
  const debouncedLoading = refDebounced(loading, ms)

  return {
    loading,
    debouncedLoading,
  }
}
