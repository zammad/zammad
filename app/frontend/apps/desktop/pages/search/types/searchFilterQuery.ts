// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export type FilterField = 'name' | 'operator' | 'value'

export interface FilterKeyParts {
  index: number
  field: FilterField
  // Remaining segments after `filter.<index>.<field>`. Empty for the exact
  // cell (`filter.0.value`); populated for nested value paths like
  // `filter.0.value.from` → `['from']` once compound value codecs land.
  rest: string[]
}

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
