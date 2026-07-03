// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useCssVar } from '@vueuse/core'
import { watch, type Ref } from 'vue'

/**
 * Needs to be used whenever we have an absolute of fixed positioned element
 * that needs to be placed below the top header and the height
 * of the top header can change.
 *
 * Otherwise you can always inline scope the --top-header-height in case
 * of multiple instances on one screen which rely on a different value
 */
export const useStickyTopCalculator = (
  currentVisibleHeaderHeight: Ref<number>,
  options = { offset: 0 },
) => {
  const topHeaderHeight = useCssVar('--top-header-height', undefined, {
    initialValue: `${(currentVisibleHeaderHeight.value ?? 0) + options.offset}px`,
  })

  watch(
    currentVisibleHeaderHeight,
    (height) => {
      topHeaderHeight.value = `${height + options.offset}px`
    },
    {
      immediate: true,
      flush: 'post',
    },
  )

  return { currentVisibleHeaderHeight }
}
