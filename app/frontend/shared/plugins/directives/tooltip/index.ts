// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type ObjectDirective } from 'vue'

import { useAppName } from '#shared/composables/useAppName.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

interface Modifiers {
  truncate?: boolean
}

let isListeningToEvents = false
let isTooltipInDom = false
let hasHoverOnNode = false
let currentEvent: MouseEvent | TouchEvent | null = null
let tooltipTimeout: NodeJS.Timeout | null = null

let tooltipRecordsCount = 0

let tooltipTargetRecords: WeakMap<HTMLElement, { modifiers: Modifiers }> =
  new WeakMap()

const removeTooltips = () => {
  document
    .querySelectorAll('[role="tooltip"]')
    .forEach((node) => node?.remove())
  isTooltipInDom = false
}

const addModifierRecord = (element: HTMLDivElement, modifiers: Modifiers) => {
  if (tooltipTargetRecords.has(element)) return

  tooltipRecordsCount += 1
  tooltipTargetRecords.set(element, {
    modifiers,
  })
}

const removeModifierRecord = (element: HTMLDivElement) => {
  if (!tooltipTargetRecords.has(element)) return
  tooltipRecordsCount -= 1
  tooltipTargetRecords.delete(element)
}

const getModifierRecord = ($el: HTMLDivElement) => {
  return tooltipTargetRecords.get($el) || null
}

const createTooltip = (
  { top, left }: { top: string; left: string },
  message: string,
) => {
  const tooltipNode = document.createElement('div')
  tooltipNode.classList.add('tooltip')

  tooltipNode.style.top = top
  tooltipNode.style.left = left
  tooltipNode.setAttribute('aria-hidden', 'true')
  tooltipNode.setAttribute('role', 'tooltip')

  // Set the max-width to half of the available width
  const availableWidth = window.innerWidth / 2
  tooltipNode.style.maxWidth = `${availableWidth}px`

  const tooltipMessageNode = document.createElement('p')
  tooltipMessageNode.textContent = message

  tooltipNode.insertAdjacentElement('afterbegin', tooltipMessageNode)

  return tooltipNode
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

const addTooltip = (
  targetNode: HTMLDivElement,
  message: string,
  {
    event,
  }: {
    event: MouseEvent | TouchEvent
  },
) => {
  if (!event) return

  const tooltipNode = createTooltip({ top: '0px', left: '0px' }, message)
  document.body.appendChild(tooltipNode) // Temporarily add to DOM to calculate dimensions

  const tooltipRectangle = tooltipNode.getBoundingClientRect()

  let top: string
  let left: string
  if (!event) return
  if ('touches' in event) {
    const { clientX, clientY } = event.touches[0]

    top = `${clientY}px`
    left = getLeftBasedOnLanguage(clientX, tooltipRectangle)
  } else {
    const { clientX, clientY } = event
    const verticalThreshold = 10 // native tooltip has an extra threshold of ~ 10px
    const thresholdToBottom = 30

    const availableSpaceBelow = window.innerHeight - clientY - thresholdToBottom

    // If the tooltip is to close to the bottom of the viewport, show it above the target
    if (availableSpaceBelow < tooltipRectangle.height) {
      top = `${clientY - verticalThreshold - tooltipRectangle.height}px`
    } else {
      top = `${clientY + verticalThreshold}px`
    }
    left = getLeftBasedOnLanguage(clientX, tooltipRectangle)
  }

  tooltipNode.style.top = top
  tooltipNode.style.left = left

  document.body.insertAdjacentElement('beforeend', tooltipNode)

  setTimeout(() => {
    tooltipNode.classList.add('tooltip-animate')
  }, 500) // Add animation after 500ms same as for delay
}

const isContentTruncated = (element: HTMLElement) => {
  const { parentElement } = element
  // top-level element
  if (!parentElement) return element.offsetWidth < element.scrollWidth

  return parentElement.offsetWidth < parentElement.scrollWidth
}

const evaluateModifiers = (element: HTMLElement, options?: Modifiers) => {
  const modifications = {
    isTruncated: false,
    top: false,
  }

  if (options?.truncate) {
    modifications.isTruncated = isContentTruncated(element)
  }

  return modifications
}

const findTooltipTarget = (
  element: HTMLDivElement | null,
): HTMLDivElement | null => element?.closest('[data-tooltip]') || null

const handleTooltipAddEvent = (event: MouseEvent | TouchEvent) => {
  if (isTooltipInDom) removeTooltips() // Remove tooltips if there is already one set in the DOM

  if (!event.target) return

  // Do not show the tooltip if the target element is missing.
  const tooltipTargetNode = findTooltipTarget(event.target as HTMLDivElement)
  if (!tooltipTargetNode) return

  // Do not show the tooltip if the message is absent or empty.
  const message = tooltipTargetNode.getAttribute('aria-label')
  if (!message) return

  // Do not show the tooltip if it was temporarily suspended.
  //   This is signaled by any ancestors having a special CSS class assigned.
  if (tooltipTargetNode.closest('.no-tooltip')) return

  hasHoverOnNode = true // Set it to capture mousemove event

  const tooltipRecord = getModifierRecord(tooltipTargetNode)

  const { isTruncated } = evaluateModifiers(
    tooltipTargetNode,
    tooltipRecord?.modifiers,
  )

  // If the content gets truncated and the modifier is set to only show the tooltip on truncation
  if (!isTruncated && tooltipRecord?.modifiers.truncate) return

  if (tooltipTimeout) clearTimeout(tooltipTimeout)

  tooltipTimeout = setTimeout(() => {
    addTooltip(tooltipTargetNode, message as string, {
      event: currentEvent as MouseEvent,
    })
    isTooltipInDom = true
  }, 300) // Sets a delay before showing tooltip as native
}

const handleEvent = (event: MouseEvent | TouchEvent) => {
  if (hasHoverOnNode) currentEvent = event
}

const handleTooltipRemoveEvent = () => {
  if (tooltipTimeout) clearTimeout(tooltipTimeout)
  if (isTooltipInDom) removeTooltips()
}

const addEventListeners = () => {
  window.addEventListener('scroll', handleTooltipRemoveEvent, {
    passive: true,
    capture: true,
  }) // important to catch scroll event in capturing phase

  window.addEventListener('touchstart', handleTooltipAddEvent, {
    passive: true,
  })
  window.addEventListener('touchmove', handleEvent, {
    passive: true,
  })
  window.addEventListener('touchcancel', handleTooltipRemoveEvent, {
    passive: true,
  })

  window.addEventListener('mouseover', handleTooltipAddEvent, {
    passive: true,
  })
  window.addEventListener('mousemove', handleEvent, {
    passive: true,
  })
  window.addEventListener('mouseout', handleTooltipRemoveEvent, {
    passive: true,
  })
}

const cleanupEventHandlers = () => {
  window.removeEventListener('touchstart', handleTooltipAddEvent)
  window.removeEventListener('touchmove', handleEvent)
  window.removeEventListener('touchcancel', handleTooltipRemoveEvent)

  window.removeEventListener('mouseover', handleTooltipAddEvent)
  window.removeEventListener('mousemove', handleEvent)
  window.removeEventListener('mouseout', handleTooltipRemoveEvent)

  window.removeEventListener('scroll', handleTooltipRemoveEvent)
}

const cleanupAndAddEventListeners = () => {
  cleanupEventHandlers()
  addEventListeners()
}

export default {
  name: 'tooltip',
  directive: {
    mounted: (element: HTMLDivElement, { value: message, modifiers }) => {
      if (!message) return

      element.setAttribute('aria-label', message)

      // Mobile does not have tooltips, hence we don't apply the rest of the logic
      if (useAppName() === 'mobile') return

      element.setAttribute('data-tooltip', 'true')

      addModifierRecord(element, modifiers)

      if (!isListeningToEvents) {
        addEventListeners()
        isListeningToEvents = true
        // Resize we cannot add it into the cleanup function
        window.addEventListener('resize', cleanupAndAddEventListeners)
      }
    },
    updated(element: HTMLDivElement, { value: message }) {
      if (!message) {
        if (element.getAttribute('aria-label'))
          element.removeAttribute('aria-label')
        return
      }

      // In some cases, we update the aria-label on an interval f.e table time cells
      // We don't want to write to the DOM on every update if nothing has changed
      if (element.getAttribute('aria-label') !== message)
        element.setAttribute('aria-label', message)
    },
    beforeUnmount(element) {
      // If we dynamically remove the element from the DOM, we need to remove it from the tooltipTargetRecords
      removeModifierRecord(element)

      // If there are no more elements with the tooltip directive, remove event listeners
      if (tooltipRecordsCount !== 1) return

      // Cleanup only on the last element
      if (isTooltipInDom) removeTooltips()

      if (isListeningToEvents) cleanupEventHandlers()

      isListeningToEvents = false
      tooltipTargetRecords = new WeakMap()
      tooltipRecordsCount = 0

      window.removeEventListener('resize', cleanupAndAddEventListeners)
    },
  },
} as {
  name: string
  directive: ObjectDirective
}
