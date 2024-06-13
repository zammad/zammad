// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useTransitionConfig } from '#shared/composables/useTransitionConfig.ts'

export const useTransitionCollapse = () => {
  const { durations } = useTransitionConfig()
  const collapseDuration = durations.normal

  const collapseEnter = (element: Element | HTMLElement) => {
    if (!(element instanceof HTMLElement)) return

    element.style.height = 'auto'

    const { height } = getComputedStyle(element)

    // Set the height of the element to zero for the enter transition.
    element.style.height = '0'

    requestAnimationFrame(() => {
      setTimeout(() => {
        element.style.height = height
      })
    })
  }

  const collapseAfterEnter = (element: Element | HTMLElement) => {
    if (!(element instanceof HTMLElement)) return

    // Set the height of the element to automatic for after the enter transition.
    element.style.height = 'auto'
  }

  const collapseLeave = (element: Element | HTMLElement) => {
    if (!(element instanceof HTMLElement)) return

    const { height } = getComputedStyle(element)

    // Set the height of the element to real height for the leave transition.
    element.style.height = height

    requestAnimationFrame(() => {
      setTimeout(() => {
        element.style.height = '0'
      })
    })
  }

  return {
    collapseDuration,
    collapseEnter,
    collapseAfterEnter,
    collapseLeave,
  }
}
