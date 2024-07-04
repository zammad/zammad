// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useScroll, useThrottleFn } from '@vueuse/core'
import { whenever } from '@vueuse/shared'
import { computed, type ComputedRef, isRef, ref, watch } from 'vue'

import type { MaybeRef } from '@vueuse/shared'

interface Options {
  scrollStartThreshold?: ComputedRef<number | undefined>
}

export const useElementScroll = (
  scrollContainerElement: MaybeRef<HTMLElement>,
  options?: Options,
) => {
  const { y, directions } = useScroll(scrollContainerElement, {
    eventListenerOptions: { passive: true },
  })

  const isScrollingDown = ref(false)
  const isScrollingUp = ref(false)

  const resetScrolls = () => {
    isScrollingDown.value = false
    isScrollingUp.value = false
  }

  const reachedTop = computed(() => y.value === 0)

  const scrollNode = computed(() =>
    isRef(scrollContainerElement)
      ? scrollContainerElement.value
      : scrollContainerElement,
  )

  const reachedBottom = computed(
    () => y.value === scrollNode.value.clientHeight,
  )

  const isScrollable = computed(
    () => scrollNode.value?.scrollHeight > scrollNode.value?.clientHeight,
  )

  const hasReachedThreshold = computed(
    () => y.value > (options?.scrollStartThreshold?.value || 0),
  )

  const omitValueChanges = computed(() => {
    return !hasReachedThreshold.value || !isScrollable.value || reachedTop.value
  })

  whenever(reachedTop, resetScrolls, { flush: 'post' })

  const throttledFn = useThrottleFn((newY, oldY) => {
    if (omitValueChanges.value) return

    if (hasReachedThreshold.value) {
      resetScrolls()
    }

    if (newY > oldY) {
      isScrollingDown.value = true
      isScrollingUp.value = false
    }

    if (newY < oldY) {
      isScrollingDown.value = false
      isScrollingUp.value = true
    }
  }, 500) // avoid scrolling glitch

  watch(y, throttledFn, { flush: 'post' })

  return {
    y,
    directions,
    reachedTop,
    reachedBottom,
    isScrollingDown,
    isScrollingUp,
    isScrollable,
  }
}
