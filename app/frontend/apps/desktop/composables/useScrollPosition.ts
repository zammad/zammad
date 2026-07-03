// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onActivated, ref, type ShallowRef } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'
import { scrollIntoView } from '#shared/utils/dom.ts'

export const useScrollPosition = (scrollContainer?: ShallowRef<HTMLElement | null>) => {
  const scrollPosition = ref<number>()

  const { hasReducedMotion } = useReducedMotion()

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

  const scrollTo = async (
    block: 'start' | 'end',
    options: { behavior: ScrollOptions['behavior'] } = { behavior: 'auto' },
  ) =>
    scrollIntoView(scrollContainer, block, {
      behavior: hasReducedMotion.value ? 'instant' : options.behavior,
      postFlush: true,
    })

  return {
    scrollPosition,
    storeScrollPosition,
    restoreScrollPosition,
    scrollIntoView: scrollTo,
  }
}
