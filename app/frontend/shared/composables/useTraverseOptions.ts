// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { onKeyStroke, unrefElement } from '@vueuse/core'

import stopEvent from '#shared/utils/events.ts'
import { getFocusableElements } from '#shared/utils/getFocusableElements.ts'
import type { FocusableOptions } from '#shared/utils/getFocusableElements.ts'

import type { MaybeRefOrGetter } from '@vueuse/shared'

type TraverseDirection = 'horizontal' | 'vertical' | 'mixed'
type ReturnValue = boolean | null | void | undefined

interface TraverseOptions extends FocusableOptions {
  onNext?(key: string, element: HTMLElement): ReturnValue
  onPrevious?(key: string, element: HTMLElement): ReturnValue
  /**
   * @default true
   */
  scrollIntoView?: boolean
  /**
   * @default 'vertical'
   */
  direction?: TraverseDirection
  filterOption?: (element: HTMLElement, index: number) => boolean
  onArrowLeft?(): ReturnValue
  onArrowRight?(): ReturnValue
  onArrowUp?(): ReturnValue
  onArrowDown?(): ReturnValue
  onHome?(): ReturnValue
  onEnd?(): ReturnValue
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

/**
 * Composable that makes it possible to select values by using keyboard arrows and home/end keys
 * @param container Parent element that has focusable options
 * @param options Configuration
 */
export const useTraverseOptions = (
  container: MaybeRefOrGetter<HTMLElement | undefined | null>,
  options: TraverseOptions = {},
) => {
  options.scrollIntoView ??= true

  onKeyStroke(
    (e) => {
      const { key } = e

      if (!processKeys.has(key)) {
        return
      }

      // If there is a rule that checks if we should continue, check it.
      //   Otherwise we assume that we should continue.
      const shouldContinue = options[`on${key}` as 'onHome']?.() ?? true

      if (!shouldContinue) return

      let elements = getFocusableElements(
        unrefElement(container) as HTMLElement,
        options,
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
    { target: container as MaybeRefOrGetter<EventTarget> },
  )
}
