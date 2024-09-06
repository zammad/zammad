// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

export const useBubbleHeader = () => {
  const showMetaInformation = ref(false)

  const isInteractiveTarget = (target: HTMLElement) => {
    if (!target) return false

    const interactiveElements = new Set(['A', 'BUTTON'])

    // Parent interactive or traversed nodes
    const hasInteractiveElements = target.closest(
      Array.from(interactiveElements).join(','),
    )

    return interactiveElements.has(target.tagName) || hasInteractiveElements
  }

  const hasSelectionRange = (target: HTMLElement) => {
    if (!target) return false

    const selection = window.getSelection()
    if (!selection || selection.type !== 'Range') return false

    return true
  }

  const toggleHeader = (event: MouseEvent) => {
    if (
      isInteractiveTarget(event.target as HTMLElement) ||
      hasSelectionRange(event.target as HTMLElement)
    )
      return

    showMetaInformation.value = !showMetaInformation.value
  }

  return {
    showMetaInformation,
    toggleHeader,
  }
}
