// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { onKeyStroke } from '@vueuse/core'
import { ref, type Ref } from 'vue'

import { getFocusableElements } from '#shared/utils/getFocusableElements.ts'

export const useTrapTab = (
  container: Ref<HTMLElement | undefined>,
  noAutoActivation = false,
) => {
  const trapFocus = (e: KeyboardEvent) => {
    const focusableElements = getFocusableElements(container.value)
    const firstFocusableElement = focusableElements[0]
    const lastFocusableElement = focusableElements[focusableElements.length - 1]

    if (e.shiftKey) {
      // if shift key pressed for shift + tab combination
      if (document.activeElement === firstFocusableElement) {
        lastFocusableElement.focus() // add focus for the last focusable element
        e.preventDefault()
      }
      return
    }

    if (document.activeElement === lastFocusableElement) {
      // if focused has reached to last focusable element then focus first focusable element after pressing tab
      firstFocusableElement.focus() // add focus for the first focusable element
      e.preventDefault()
    }
  }

  const active = ref(!noAutoActivation)

  const activateTabTrap = () => {
    active.value = true
  }

  const deactivateTabTrap = () => {
    active.value = false
  }

  onKeyStroke(
    (e) => {
      if (!active.value) return

      const isTab = e.key === 'Tab' || e.keyCode === 9

      if (!isTab) return

      trapFocus(e)
    },
    { target: container as Ref<EventTarget> },
  )

  const moveNextFocusToTrap = () => {
    if (!container.value) return

    const dummyElement = document.createElement('div')
    dummyElement.tabIndex = 0

    requestAnimationFrame(() => {
      container.value?.prepend(dummyElement)
      dummyElement.focus()
      dummyElement.remove()
    })
  }

  return {
    activateTabTrap,
    deactivateTabTrap,
    moveNextFocusToTrap,
  }
}
