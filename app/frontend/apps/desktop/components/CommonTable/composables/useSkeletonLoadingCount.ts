// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useWindowSize } from '@vueuse/core'
import { computed, type ComputedRef, type Ref } from 'vue'

export const useSkeletonLoadingCount = (
  count: Ref<number | undefined> | ComputedRef<number | undefined>,
) => {
  const { height: screenHeight } = useWindowSize()

  const visibleSkeletonLoadingCount = computed(() => {
    const maxVisibleRowCount = Math.ceil(screenHeight.value / 40)

    if (count.value && count.value > maxVisibleRowCount)
      return maxVisibleRowCount

    return count.value
  })

  return {
    visibleSkeletonLoadingCount,
  }
}
