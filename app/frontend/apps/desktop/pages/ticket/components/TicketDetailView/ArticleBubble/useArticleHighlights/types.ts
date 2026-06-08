// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export type HighlightRange = {
  startIndex: number
  endIndex: number
  colorClass: string
}

export type SelectionContext = {
  selection: Selection
  startIndex: number
  endIndex: number
  anchors: Array<CharAnchor | null>
}

export type CharAnchor = { node: Text; charIndex: number }
