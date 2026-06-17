// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { effectScope, h, render, type AppContext, type FunctionDirective, type VNode } from 'vue'

import { useLocaleStore } from '#shared/stores/locale.ts'

import type { TooltipModifiers } from './types'

const getMessageAttribute = (modifiers: TooltipModifiers) =>
  modifiers.supportive ? 'aria-description' : 'aria-label'

let isTooltipShown = false
let hasHoverOnNode = false
let currentEvent: MouseEvent | TouchEvent | null = null
let tooltipTimeout: NodeJS.Timeout | null = null
let tooltipAnimateTimeout: NodeJS.Timeout | null = null
let isListeningToEvents = false

const tooltipScope = effectScope(true)

// A single tooltip node is rendered once and then reused. Showing and hiding only
//   mutate this node, instead of mounting/unmounting it on every hover. `appContext`
//   ties the node to the app
let appContext: AppContext | null = null
let tooltipVNode: VNode | null = null
let tooltipMessageVNode: VNode | null = null

const ensureTooltipNode = () => {
  if (!tooltipVNode) {
    tooltipMessageVNode = h('p')
    tooltipVNode = h(
      'div',
      {
        role: 'tooltip',
        class: 'tooltip',
        style: { display: 'none', pointerEvents: 'none' },
      },
      [tooltipMessageVNode],
    )
    tooltipVNode.appContext = appContext

    render(tooltipVNode, document.querySelector('body')!)
  }

  return {
    tooltip: tooltipVNode.el as HTMLElement,
    message: tooltipMessageVNode!.el as HTMLElement,
  }
}

const hideTooltip = () => {
  if (tooltipAnimateTimeout) clearTimeout(tooltipAnimateTimeout)

  isTooltipShown = false

  const tooltip = tooltipVNode?.el as HTMLElement | undefined
  if (!tooltip) return

  tooltip.classList.remove('tooltip-animate')
  tooltip.style.display = 'none'

  // Drop the role and message so the hidden node is invisible to assistive
  //   technology (and DOM queries) while it is not shown.
  tooltip.removeAttribute('role')
  tooltip.removeAttribute('aria-hidden')
  if (tooltipMessageVNode?.el) (tooltipMessageVNode.el as HTMLElement).textContent = ''
}

const getLeftBasedOnLanguage = (clientX: number, tooltipRectangle: DOMRect) => {
  const isRTL = useLocaleStore().localeData?.dir === 'rtl'

  let left = ''

  if (isRTL) {
    // For RTL languages, place the tooltip to the left of the mouse
    const leftValue = clientX - tooltipRectangle.width
    left = `${leftValue}px`
    // Check if the tooltip would overflow the window's width
    if (leftValue < 0) {
      // If it would, adjust the left property to ensure it fits within the window
      left = '0px'
    }
  } else {
    // For LTR languages, place the tooltip to the right of the mouse
    left = `${clientX}px`
    // Check if the tooltip would overflow the window's width
    if (clientX + tooltipRectangle.width > window.innerWidth) {
      // Move tooltip to the left if it overflows to avoid squeezing the tooltip content
      left = `${window.innerWidth - tooltipRectangle.width}px`
    }
  }

  return left
}

const getTooltipPosition = (event: MouseEvent | TouchEvent, tooltipRectangle: DOMRect) => {
  if ('touches' in event) {
    const clientX = event.touches[0]?.clientX ?? 0
    const clientY = event.touches[0]?.clientY ?? 0

    return { top: `${clientY}px`, left: getLeftBasedOnLanguage(clientX, tooltipRectangle) }
  }

  const { clientX, clientY } = event
  const verticalThreshold = 10 // native tooltip has an extra threshold of ~ 10px
  const thresholdToBottom = 30

  const availableSpaceBelow = window.innerHeight - clientY - thresholdToBottom

  // If the tooltip is too close to the bottom of the viewport, show it above the target
  const top =
    availableSpaceBelow < tooltipRectangle.height
      ? `${clientY - verticalThreshold - tooltipRectangle.height}px`
      : `${clientY + verticalThreshold}px`

  return { top, left: getLeftBasedOnLanguage(clientX, tooltipRectangle) }
}

const showTooltip = (message: string, event: MouseEvent | TouchEvent | null) => {
  if (!event) return

  const { tooltip, message: messageNode } = ensureTooltipNode()

  messageNode.textContent = message
  tooltip.setAttribute('role', 'tooltip')
  tooltip.setAttribute('aria-hidden', 'true')

  // Reset to a measurable, unanimated state before positioning.
  tooltip.classList.remove('tooltip-animate')
  tooltip.style.display = ''
  tooltip.style.maxWidth = `${window.innerWidth / 2}px` // half of the available width
  tooltip.style.top = '0px'
  tooltip.style.left = '0px'

  const { top, left } = getTooltipPosition(event, tooltip.getBoundingClientRect())
  tooltip.style.top = top
  tooltip.style.left = left

  isTooltipShown = true

  // Fade in after the same delay as before (matches the native-like reveal).
  tooltipAnimateTimeout = setTimeout(() => tooltip.classList.add('tooltip-animate'), 500)
}

const isContentTruncated = (element: HTMLElement) => {
  // The element may itself be truncating (e.g. via a `truncate` utility class).
  if (element.offsetWidth < element.scrollWidth) return true

  // Otherwise check the parent — covers cases where the directive is set on
  //   inner content inside a truncating container.
  const { parentElement } = element
  if (!parentElement) return false

  return parentElement.offsetWidth < parentElement.scrollWidth
}

const findTooltipTarget = (element: HTMLDivElement | null): HTMLDivElement | null =>
  element?.closest('[data-tooltip]') || null

const handleTooltipAddEvent = (event: MouseEvent | TouchEvent) => {
  if (isTooltipShown) hideTooltip() // Hide a tooltip that is already shown.

  if (!event.target) return

  // Do not show the tooltip if the target element is missing.
  const tooltipTargetNode = findTooltipTarget(event.target as HTMLDivElement)
  if (!tooltipTargetNode) return

  // Do not show the tooltip if the message is absent or empty.
  //   The message lives in `aria-label`, or in `aria-description` when the
  //   `supportive` modifier opts out of setting `aria-label`.
  const message =
    tooltipTargetNode.getAttribute('aria-label') ||
    tooltipTargetNode.getAttribute('aria-description')
  if (!message) return

  // Do not show the tooltip if it was temporarily suspended.
  //   This is signaled by any ancestors having a special CSS class assigned.
  if (tooltipTargetNode.closest('.no-tooltip')) return

  hasHoverOnNode = true // Set it to capture mousemove event
  currentEvent = event

  // With the `truncate` modifier, only show the tooltip when the content is truncated.
  //   The modifier is persisted on the element as `data-tooltip="truncate"`.
  if (
    tooltipTargetNode.getAttribute('data-tooltip') === 'truncate' &&
    !isContentTruncated(tooltipTargetNode)
  )
    return

  if (tooltipTimeout) clearTimeout(tooltipTimeout)

  tooltipTimeout = setTimeout(() => {
    showTooltip(message, currentEvent)
  }, 300) // Sets a delay before showing tooltip as native
}

const handleEvent = (event: MouseEvent | TouchEvent) => {
  if (hasHoverOnNode) currentEvent = event
}

const handleTooltipRemoveEvent = () => {
  if (tooltipTimeout) clearTimeout(tooltipTimeout)
  hasHoverOnNode = false
  currentEvent = null

  if (isTooltipShown) hideTooltip()
}

const startListeningToEvents = () => {
  if (isListeningToEvents) return
  isListeningToEvents = true

  tooltipScope.run(() => {
    useEventListener(window, 'scroll', handleTooltipRemoveEvent, { passive: true, capture: true })
    useEventListener(window, ['mouseover', 'touchstart'], handleTooltipAddEvent, { passive: true })
    useEventListener(window, ['mousemove', 'touchmove'], handleEvent, { passive: true })
    useEventListener(
      window,
      ['mouseout', 'mousedown', 'touchcancel', 'resize'],
      handleTooltipRemoveEvent,
      { passive: true },
    )
  })
}

const options = {
  hideTooltip: false,
}

// A function directive runs the same callback on `mounted` and `updated` —
//  The tooltip system is an app-lifetime singleton
const tooltipDirective: FunctionDirective<HTMLDivElement, unknown, keyof TooltipModifiers> = (
  element,
  { value, modifiers, instance },
) => {
  if (typeof value !== 'string') return

  const attribute = getMessageAttribute(modifiers)

  // In some cases the message is updated on an interval (e.g. table time cells), so
  //   only write to the DOM when it actually changed.
  if (element.getAttribute(attribute) !== value) element.setAttribute(attribute, value)

  // Everything below only needs to take effect once
  appContext ??= instance?.$.appContext ?? null

  if (options?.hideTooltip) return

  element.setAttribute('data-tooltip', modifiers.truncate ? 'truncate' : 'true')
  startListeningToEvents()
}

export const setOptions = (newOptions: typeof options) => {
  Object.assign(options, newOptions)
}

export default {
  name: 'tooltip',
  directive: tooltipDirective,
}
