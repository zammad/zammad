// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTimeoutFn } from '@vueuse/core'
import { type Ref, type ComputedRef, ref, watch } from 'vue'

// Reach for this only where a flash would disrupt a view that is already meaningfully there: a
//   hover-triggered popover (a passing cursor should not flicker), pagination appending to a list
//   already on screen, a sidebar widget updating next to content that still reads fine, or a
//   submit spinner. What all of those share is a previous, still-valid state worth protecting for
//   a moment.
//
// `CommonLoader`, by contrast, no longer debounces (see its own comment) - a cold or navigational
//   load has nothing worth protecting behind it, so its skeleton shows immediately instead of a
//   blank spacer for the same window. Debouncing there traded one flash (an unlabelled empty box)
//   for another (a delayed skeleton), without actually avoiding one. Do not reach for this
//   composable to "fix" a `CommonLoader` flash for that reason - it would reintroduce the same
//   trade-off `CommonLoader` deliberately dropped.
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
