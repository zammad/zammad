// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getFocusableElements } from '@shared/utils/getFocusableElements'
import { onKeyStroke } from '@vueuse/core'
import type { Ref } from 'vue'

export const useTrapTab = (container: Ref<HTMLElement | undefined>) => {
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

  onKeyStroke(
    (e) => {
      const isTab = e.key === 'Tab' || e.keyCode === 9

      if (isTab) {
        trapFocus(e)
      }
    },
    { target: container as Ref<EventTarget> },
  )
}
