// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTimeout } from '@vueuse/core'
import { ref } from 'vue'

import { useHighlightMenuState } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/useHighlightMenuState.ts'

export const useBubbleHeader = () => {
  const showMetaInformation = ref(false)

  const { isActive } = useHighlightMenuState()

  const isInteractiveTarget = (target: HTMLElement) => {
    if (!target) return false

    const interactiveElements = new Set(['A', 'BUTTON'])

    // Parent interactive or traversed nodes
    const hasInteractiveElements = target.closest(Array.from(interactiveElements).join(','))

    return interactiveElements.has(target.tagName) || hasInteractiveElements
  }

  const hasSelectionRange = (target: HTMLElement) => {
    if (!target) return false

    const selection = window.getSelection()
    if (!selection || selection.type !== 'Range') return false

    return true
  }

  const { start, stop } = useTimeout(200, {
    controls: true,
    callback: () => {
      showMetaInformation.value = !showMetaInformation.value
    },
    immediate: false,
  })

  const toggleHeader = async (event: MouseEvent) => {
    stop()

    if (
      event.detail === 2 || // Double-click
      isInteractiveTarget(event.target as HTMLElement) ||
      hasSelectionRange(event.target as HTMLElement)
    )
      return

    // When the top-bar has activated the highlight feature/
    // We don't allow expansion and collapsing

    if (isActive.value) return

    start()
  }

  return {
    showMetaInformation,
    toggleHeader,
  }
}
