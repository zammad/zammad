// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTimeoutFn } from '@vueuse/core'
import { type Ref, type ComputedRef, ref, watch } from 'vue'

export const useDebouncedLoading = ({
  ms = 300,
  isLoading,
}: {
  ms?: number
  isLoading?: Ref<boolean> | ComputedRef<boolean>
} = {}) => {
  const delay = VITE_TEST_MODE ? 0 : ms
  const loading = ref(false)
  const source = isLoading ?? loading
  const debouncedLoading = ref(false)

  let canHide = true
  let pendingHide = false

  const { start: startMin } = useTimeoutFn(
    () => {
      canHide = true
      if (pendingHide) {
        pendingHide = false
        debouncedLoading.value = false
      }
    },
    delay,
    { immediate: false },
  )

  const { start: startShow, stop: cancelShow } = useTimeoutFn(
    () => {
      canHide = false
      debouncedLoading.value = true
      startMin()
    },
    delay,
    { immediate: false },
  )

  watch(
    source,
    (newVal) => {
      if (newVal) {
        pendingHide = false
        startShow()
      } else {
        cancelShow()
        if (canHide) {
          debouncedLoading.value = false
        } else {
          pendingHide = true
        }
      }
    },
    { immediate: true },
  )

  return { loading, isLoading: source, debouncedLoading }
}
