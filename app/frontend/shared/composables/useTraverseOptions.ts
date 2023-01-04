// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import stopEvent from '@shared/utils/events'
import { getFocusableElements } from '@shared/utils/getFocusableElements'
import { onKeyStroke, unrefElement } from '@vueuse/core'
import type { MaybeComputedRef } from '@vueuse/shared'

type TraverseDirection = 'horizontal' | 'vertical' | 'mixed'

interface TraverseOptions {
  onNext?(key: string, element: HTMLElement): boolean | null | void
  onPrevious?(key: string, element: HTMLElement): boolean | null | void
  /**
   * @default true
   */
  scrollIntoView?: boolean
  direction?: TraverseDirection
  filterOption?: (element: HTMLElement, index: number) => boolean
  onArrowLeft?(): boolean | null | void
  onArrowRight?(): boolean | null | void
  onArrowUp?(): boolean | null | void
  onArrowDown?(): boolean | null | void
  onHome?(): boolean | null | void
  onEnd?(): boolean | null | void
}

const processKeys = new Set([
  'Home',
  'End',
  'ArrowLeft',
  'ArrowRight',
  'ArrowUp',
  'ArrowDown',
])

const isNext = (key: string, direction: TraverseDirection = 'vertical') => {
  if (direction === 'horizontal') return key === 'ArrowRight'
  if (direction === 'vertical') return key === 'ArrowDown'
  return key === 'ArrowDown' || key === 'ArrowUp'
}

const isPrevious = (key: string, direction: TraverseDirection = 'vertical') => {
  if (direction === 'horizontal') return key === 'ArrowLeft'
  if (direction === 'vertical') return key === 'ArrowUp'
  return key === 'ArrowUp' || key === 'ArrowLeft'
}

const getNextElement = (
  elements: HTMLElement[],
  key: string,
  options: TraverseOptions,
) => {
  const currentIndex = elements.indexOf(document.activeElement as HTMLElement)

  if (isNext(key, options.direction)) {
    const nextElement = elements[currentIndex + 1] || elements[0]
    const goNext = options.onNext?.(key, nextElement) ?? true
    if (!goNext) return null
    return nextElement
  }

  if (isPrevious(key, options.direction)) {
    const previousElement =
      elements[currentIndex - 1] || elements[elements.length - 1]
    const goPrevious = options.onPrevious?.(key, previousElement) ?? true
    if (!goPrevious) return null
    return previousElement
  }

  if (key === 'Home') {
    return elements[0]
  }

  if (key === 'End') {
    return elements[elements.length - 1]
  }
  return null
}

export const useTraverseOptions = (
  container: MaybeComputedRef<HTMLElement | undefined | null>,
  options: TraverseOptions = {},
) => {
  options.scrollIntoView ??= true

  onKeyStroke(
    (e) => {
      const { key } = e

      if (!processKeys.has(key)) {
        return
      }

      const shouldContinue = options[`on${key}` as 'onHome']?.() ?? true

      if (!shouldContinue) return

      let elements = getFocusableElements(
        unrefElement(container) as HTMLElement,
      )

      if (options.filterOption) {
        elements = elements.filter(options.filterOption)
      }

      if (!elements.length) return

      const nextElement = getNextElement(elements, key, options)

      if (!nextElement) return

      stopEvent(e)
      nextElement.focus()
      if (options.scrollIntoView) {
        nextElement.scrollIntoView({ block: 'nearest' })
      }
    },
    { target: container as MaybeComputedRef<EventTarget> },
  )
}
