// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { refDebounced } from '@vueuse/shared'
import { type Ref, type ComputedRef, ref } from 'vue'

export const useDebouncedLoading = ({
  ms,
  isLoading,
}: {
  ms?: number
  isLoading?: Ref<boolean> | ComputedRef<boolean>
} = {}) => {
  const loading = ref(false)
  const debouncedLoading = refDebounced(isLoading ?? loading, ms ?? 300)

  return {
    loading,
    debouncedLoading,
  }
}
