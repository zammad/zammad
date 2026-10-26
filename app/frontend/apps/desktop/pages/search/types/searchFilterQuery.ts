// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export interface ParsedFilter {
  name?: unknown
  operator?: unknown
  value?: unknown
  // Operator-specific extras (e.g. the `range` unit of relative operators)
  // round-trip alongside `value`.
  [key: string]: unknown
}

export interface ValidFilterCandidate {
  name: string
  operator: string
  value: unknown
  [key: string]: unknown
}
