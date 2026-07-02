// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, onActivated, ref, type ShallowRef } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'
import { waitForAnimationFrame } from '#shared/utils/helpers.ts'

export const useScrollPosition = (scrollContainer?: ShallowRef<HTMLElement | null>) => {
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

  const { hasReducedMotion } = useReducedMotion()

  const scrollIntoView = async (
    block: 'start' | 'end',
    options: { behavior: ScrollOptions['behavior'] } = {
      behavior: hasReducedMotion.value ? 'instant' : 'smooth',
    },
  ) => {
    const { behavior } = options

    await nextTick()
    await waitForAnimationFrame()

    const container = scrollContainer?.value
    if (!container || !container?.scrollTo) return

    const top = block === 'start' ? 0 : container.scrollHeight

    container?.scrollTo({
      behavior,
      top,
    })
  }

  return {
    scrollPosition,
    storeScrollPosition,
    restoreScrollPosition,
    scrollIntoView,
  }
}
