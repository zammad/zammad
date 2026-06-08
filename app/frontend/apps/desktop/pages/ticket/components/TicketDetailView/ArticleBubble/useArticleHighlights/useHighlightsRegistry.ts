// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { readonly } from 'vue'

// Needs to be registered globally to be used in CSS.highlight()
// but we want to keep track of it in a registry to be able to clean up deleted highlights.
// ⚠️ keep in mind across views to clear and reactivate it with keep alive
const highlightRegistry = new Map<string, Highlight>()

export const useHighlightsRegistry = () => {
  const getRegistry = (colorClass: string) => highlightRegistry.get(colorClass)

  const setRegistry = (colorClass: string) => {
    const highlight = new Highlight()

    highlightRegistry.set(colorClass, highlight)

    CSS.highlights.set(colorClass, highlight)

    return highlightRegistry
  }

  const getOrCreateHighlight = (colorClass: string): Highlight | undefined => {
    if (!('highlights' in CSS)) return undefined

    if (!highlightRegistry.has(colorClass)) setRegistry(colorClass)

    return getRegistry(colorClass)
  }

  const removeHighlightFromRegistry = (colorClass: string, range: Range) =>
    getRegistry(colorClass)?.delete(range)

  return {
    highlightRegistry: readonly(highlightRegistry),
    getOrCreateHighlight,
    removeHighlightFromRegistry,
  }
}
