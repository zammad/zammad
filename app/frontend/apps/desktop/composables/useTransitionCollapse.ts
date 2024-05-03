// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const useTransitionCollapse = () => {
  const collapseDuration = VITE_TEST_MODE ? undefined : 200

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
