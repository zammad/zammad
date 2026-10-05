// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTimeout } from '@vueuse/core'
import { ref } from 'vue'

import { useHighlightMenuState } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/composables/useHighlightMenuState.ts'

// Default double-click interval of macOS and Windows, browsers do not expose the configured one.
const TOGGLE_DELAY = 500

export const useBubbleHeader = () => {
  const showMetaInformation = ref(false)

  const { isActive } = useHighlightMenuState()

  // Set when a click toggled the header, so that a slower double-click than the delay can revert it.
  let toggledByLastClick = false

  const isInteractiveTarget = (target: HTMLElement) => {
    if (!target) return false

    const interactiveElements = new Set(['A', 'BUTTON'])

    // Parent interactive or traversed nodes
    const hasInteractiveElements = target.closest(Array.from(interactiveElements).join(','))

    return interactiveElements.has(target.tagName) || hasInteractiveElements
  }

  const hasSelectionRange = () => window.getSelection()?.type === 'Range'

  const { start, stop } = useTimeout(TOGGLE_DELAY, {
    controls: true,
    callback: () => {
      if (hasSelectionRange() || isActive.value) return

      showMetaInformation.value = !showMetaInformation.value
      toggledByLastClick = true
    },
    immediate: false,
  })

  const toggle = () => {
    stop()
    toggledByLastClick = false

    // When the top-bar has activated the highlight feature/
    // We don't allow expansion and collapsing
    if (isActive.value) return

    showMetaInformation.value = !showMetaInformation.value
  }

  const toggleHeader = (event: MouseEvent) => {
    stop()

    // Double- and triple-click
    if (event.detail > 1) {
      if (toggledByLastClick) showMetaInformation.value = !showMetaInformation.value

      toggledByLastClick = false

      return
    }

    toggledByLastClick = false

    if (isInteractiveTarget(event.target as HTMLElement) || hasSelectionRange() || isActive.value)
      return

    start()
  }

  return {
    showMetaInformation,
    toggle,
    toggleHeader,
  }
}
