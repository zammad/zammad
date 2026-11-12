// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createSharedComposable } from '@vueuse/shared'
import { computed, shallowReactive } from 'vue'

// The message inputs of the open chat windows, for the Tab loop between them of the old interface:
//   a composer registers its input while it is mounted, so a window without one is not in the loop.
export const useChatMessageInputs = createSharedComposable(() => {
  const inputs = shallowReactive(new Set<HTMLElement>())

  // With a single input there is no loop: Tab and Escape keep their meaning.
  const hasLoop = computed(() => inputs.size > 1)

  const registerInput = (input: HTMLElement) => {
    inputs.add(input)
  }

  const unregisterInput = (input: HTMLElement) => {
    inputs.delete(input)
  }

  // In document order, which is the order the windows were opened in, whatever the rows make of it.
  const orderedInputs = () =>
    [...inputs].sort((a, b) =>
      a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1,
    )

  // Around the ends, as the old interface does.
  const focusInputFrom = (input: HTMLElement, step: 1 | -1) => {
    if (!hasLoop.value) return false

    const ordered = orderedInputs()
    const index = ordered.indexOf(input)

    if (index === -1) return false

    ordered[(index + step + ordered.length) % ordered.length].focus()

    return true
  }

  const focusNextInput = (input: HTMLElement) => focusInputFrom(input, 1)

  const focusPreviousInput = (input: HTMLElement) => focusInputFrom(input, -1)

  return { hasLoop, registerInput, unregisterInput, focusNextInput, focusPreviousInput }
})
