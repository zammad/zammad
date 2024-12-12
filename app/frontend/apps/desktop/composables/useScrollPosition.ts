// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { onActivated, ref, type ShallowRef } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

export const useScrollPosition = (
  scrollContainer?: ShallowRef<HTMLElement | null>,
) => {
  const scrollPosition = ref<number>()

  const storeScrollPosition = () => {
    if (!scrollContainer?.value) return
    scrollPosition.value = scrollContainer.value?.scrollTop
  }

  const restoreScrollPosition = () => {
    if (!scrollContainer?.value || scrollPosition.value === undefined) return
    scrollContainer.value.scrollTop = scrollPosition.value
  }

  onActivated(restoreScrollPosition)
  onBeforeRouteLeave(storeScrollPosition)
  onBeforeRouteUpdate(storeScrollPosition)

  return {
    scrollPosition,
    storeScrollPosition,
    restoreScrollPosition,
  }
}
