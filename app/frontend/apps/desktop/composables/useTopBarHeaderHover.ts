// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  unrefElement,
  useEventListener,
  useMutationObserver,
  useThrottleFn,
  type MaybeElementRef,
} from '@vueuse/core'
import { computed, nextTick, readonly, ref, watch } from 'vue'

import { useReactivate } from '#shared/composables/useReactivate.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

interface Options {
  throttleMs?: number
  /**
   * A selector to identify elements that should also trigger the hover lock when focused.
   * For example, this can be used to include popover content that is focusable but not a child of the observed elements.
   * @example 'input:focus, textarea:focus'
   */
  focusedElementSelector?: string
  initialHovering?: boolean
}

export const useTopBarHeaderHover = (
  observedElements: MaybeElementRef[],
  options: Options = {},
) => {
  const { throttleMs = 100, focusedElementSelector, initialHovering = false } = options

  const { isTouchDevice } = useTouchDevice()

  const isContainerHovered = ref(false)
  const hasExpandedPopover = ref(false)
  const hasFocusedElement = ref(false)

  const isHovering = ref(initialHovering)

  // Throttle final hover state updates to avoid glitches while moving between layered elements.
  const updateIsHovering = useThrottleFn((value: boolean) => {
    isHovering.value = value

    return isHovering.value
  }, throttleMs)

  const refreshHoverState = () => {
    updateIsHovering(
      isContainerHovered.value || hasExpandedPopover.value || hasFocusedElement.value,
    )
  }

  const updateExpandedPopoverState = () => {
    hasExpandedPopover.value = observedElements.some((element) =>
      Boolean(unrefElement(element)?.querySelector('[aria-expanded="true"]')),
    )
  }

  const updateFocusedElementState = () => {
    if (!focusedElementSelector) return

    hasFocusedElement.value = observedElements.some((element) =>
      Boolean(unrefElement(element)?.querySelector(focusedElementSelector)),
    )
  }

  observedElements.forEach((element) => {
    useMutationObserver(
      element,
      (mutations) => {
        updateExpandedPopoverState()

        // Firefox does not fire `focusout` when an element is removed from the DOM (e.g. when
        // an inline edit input is destroyed after submitting or pressing Escape). Re-check the
        // focused element state on any child-list mutation to avoid the top bar getting stuck.
        if (focusedElementSelector && mutations.some((m) => m.type === 'childList'))
          nextTick(updateFocusedElementState)
      },
      {
        subtree: true,
        childList: true,
        attributes: true,
        attributeFilter: ['aria-expanded'],
      },
    )

    if (!focusedElementSelector) return

    useEventListener(() => unrefElement(element), 'focusin', updateFocusedElementState)

    useEventListener(
      () => unrefElement(element),
      'focusout',
      () => {
        // Wait for the next focus target, then recompute focus lock state.
        nextTick(updateFocusedElementState)
      },
    )
  })

  watch(observedElements, updateExpandedPopoverState, {
    immediate: true,
    flush: 'post',
  })

  watch(observedElements, updateFocusedElementState, {
    immediate: true,
    flush: 'post',
  })

  watch(hasExpandedPopover, refreshHoverState)
  watch(hasFocusedElement, refreshHoverState)

  const handleHideHeaderDetails = () => {
    isContainerHovered.value = false
    refreshHoverState()
  }

  const handleShowHeaderDetails = () => {
    isContainerHovered.value = true
    refreshHoverState()
  }

  const containerEventHandlers = computed(() =>
    isTouchDevice.value
      ? {
          touchstart: handleShowHeaderDetails,
          touchend: handleHideHeaderDetails,
        }
      : {
          mouseenter: handleShowHeaderDetails,
          mouseleave: handleHideHeaderDetails,
        },
  )

  // It can happen that when you move away of the current page
  // that some states are still cached due to keep-alive and not cleanup up
  const handleReactivation = () => {
    isContainerHovered.value = false
    hasExpandedPopover.value = false
    hasFocusedElement.value = false
    refreshHoverState()
  }

  useReactivate(handleReactivation)

  return {
    containerEventHandlers,
    isHovering: readonly(isHovering),
    updateIsHovering,
  }
}
