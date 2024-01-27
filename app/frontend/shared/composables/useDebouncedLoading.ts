// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { refDebounced } from '@vueuse/shared'

export const useDebouncedLoading = (ms = 300) => {
  const loading = ref(false)
  const debouncedLoading = refDebounced(loading, ms)

  return {
    loading,
    debouncedLoading,
  }
}
