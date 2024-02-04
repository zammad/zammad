// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getPreviousFocusableElement } from '#shared/utils/getFocusableElements.ts'

export const useDelegateFocus = (containerId: string, firstChildId: string) => {
  const delegateFocus = (event: FocusEvent) => {
    const containerElement: Maybe<HTMLElement> = document.querySelector(
      `#${containerId}`,
    )

    const firstChildElement: Maybe<HTMLElement> = document.querySelector(
      `#${firstChildId}`,
    )

    // Check if the element that just lost focus is the first child element of the container.
    if (event.relatedTarget && event.relatedTarget === firstChildElement) {
      getPreviousFocusableElement(containerElement)?.focus()

      return
    }

    // Check if the element that just lost focus is another child element of the container.
    if (
      event.relatedTarget &&
      containerElement?.contains(event.relatedTarget as Node)
    )
      return

    firstChildElement?.focus()
  }

  return {
    delegateFocus,
  }
}
