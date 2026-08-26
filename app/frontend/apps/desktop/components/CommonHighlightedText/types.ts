// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// One run of a text split into matched and unmatched parts — the shape the
//   knowledge base search previews arrive in.
export interface HighlightSegment {
  text: string
  highlight: boolean
}
