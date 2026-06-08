// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { parse, stringify, type IStringifyOptions, type IParseOptions } from 'qs'

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'

import type { ParsedFilter, ValidFilterCandidate } from '../types/searchFilterQuery'

// Dot-path query plugin for advanced search filters, backed by qs.
//
// URL shape: `filter.<index>.<name|operator|value*>=…`. qs owns parse/
// stringify on both sides — we only filter out incomplete entries and (on
// decode) validate against the attribute schema. Type coercion
// (numbers/booleans/Dates → string) and nested-value encoding come from qs;
// arrays, ranges, and object values round-trip without code changes.

const FILTER_NAMESPACE = 'filter'

// qs uses brackets for array indices even with `allowDots: true`
// (`filter[0].name`). We feed it a numeric-keyed object on encode and let it
// auto-rebuild the array on decode (numeric-keyed maps under `arrayLimit`
// get promoted back to arrays).
const QS_OPTIONS: IStringifyOptions & IParseOptions = {
  allowDots: true,
  arrayLimit: 500,
}

export const isFilterParamKey = (key: string): boolean =>
  key === FILTER_NAMESPACE || key.startsWith(`${FILTER_NAMESPACE}.`)

// Whether a filter value carries a real constraint. Arrays (e.g. the
// `[min, max]` of `in range`) count only if some element does, so an all-blank
// range is dropped rather than forwarded to the backend (which rejects it).
export const isMeaningfulFilterValue = (value: unknown): boolean => {
  if (value === null || value === undefined || value === '') return false
  if (Array.isArray(value)) return value.some(isMeaningfulFilterValue)
  return true
}

// Single predicate used on both sides: a filter is encodable iff it carries
// a non-empty `name`/`operator` and a meaningful `value`. Object/array values
// pass — qs nests them under `filter.<i>.value.*` automatically.
const isValidFilter = (entry: unknown): entry is ValidFilterCandidate => {
  if (!entry || typeof entry !== 'object') return false
  const candidate = entry as Record<string, unknown>

  if (typeof candidate.name !== 'string' || candidate.name === '') return false
  if (typeof candidate.operator !== 'string' || candidate.operator === '') return false

  return isMeaningfulFilterValue(candidate.value)
}

export const encodeFilters = (filters: FilterSelectorEntry[]): Record<string, string> => {
  // Drop incomplete entries and re-index from 0 — qs takes care of the rest.
  const indexed = Object.fromEntries(filters.filter(isValidFilter).entries())
  const encoded = stringify({ [FILTER_NAMESPACE]: indexed }, QS_OPTIONS)

  return Object.fromEntries(new URLSearchParams(encoded))
}

// vue-router's `route.query` is already URL-decoded — re-encode via
// URLSearchParams so qs.parse can do a clean split (an `&` or `=` inside a
// value would otherwise corrupt the boundary). Multi-value keys become
// repeated pairs.
const queryRecordToString = (query: Record<string, unknown>): string => {
  const params = new URLSearchParams()

  Object.entries(query).forEach(([key, value]) => {
    if (typeof value === 'string') {
      params.append(key, decodeURIComponent(value))

      return
    }

    if (!Array.isArray(value)) return

    value
      .filter((entry): entry is string => typeof entry === 'string')
      .forEach((entry) => params.append(key, decodeURIComponent(entry)))
  })

  return params.toString()
}

// Relation-typed attributes carry integer primary-key IDs. URL query params
// always arrive as strings, so coerce here so downstream consumers (FormKit
// select equality, taskbar sync, autocomplete initial option lookup) see the
// value type the schema implies. Strings that aren't integers stay as-is —
// they won't match a valid option either way, no need to silently turn "foo"
// into NaN.
//
// `attribute.relation` is the single source of truth for "value is a
// foreign-key ID". Tag-style autocompletes deliberately leave it unset since
// their values are strings (tag names), so a numeric-looking tag like "5"
// round-trips as the string "5", not the integer 5.
const coerceValueForAttribute = (value: unknown, attribute: FilterAttribute): unknown => {
  if (!attribute.relation) return value

  const coerce = (v: unknown) => {
    if (typeof v !== 'string' || v === '') return v
    const n = Number(v)
    return Number.isInteger(n) ? n : v
  }

  return Array.isArray(value) ? value.map(coerce) : coerce(value)
}

const resolveAgainstSchema = (
  candidate: ValidFilterCandidate,
  attributes: FilterAttribute[],
): FilterSelectorEntry | null => {
  const attribute = attributes.find((entry) => entry.name === candidate.name)

  if (!attribute) return null

  if (!attribute.operators.includes(candidate.operator)) return null

  // Preserve operator extras (e.g. `range`) — only `name`/`value` are
  // normalised against the schema; everything else rides through unchanged.
  return {
    ...candidate,
    name: attribute.name,
    operator: candidate.operator,
    value: coerceValueForAttribute(candidate.value, attribute),
  }
}

export const decodeFilters = (
  query: Record<string, unknown>,
  attributes: FilterAttribute[] = [],
): FilterSelectorEntry[] => {
  const parsed = parse(queryRecordToString(query), QS_OPTIONS) as Record<string, unknown>
  const raw = parsed[FILTER_NAMESPACE]
  const candidates: ParsedFilter[] = Array.isArray(raw) ? raw : []

  return candidates.flatMap((candidate) => {
    if (!isValidFilter(candidate)) return []
    if (attributes.length === 0) {
      // Schema not loaded yet — keep the candidate intact (incl. operator
      // extras like `range`); it is re-resolved once attributes arrive.
      return [{ ...candidate }]
    }

    const resolved = resolveAgainstSchema(candidate, attributes)

    return resolved ? [resolved] : []
  })
}

export const getSearchQueryWithoutFilters = (
  query: Record<string, unknown>,
): Record<string, string> =>
  Object.fromEntries(
    Object.entries(query).flatMap(([key, value]) => {
      if (key === 'entity' || isFilterParamKey(key)) return []
      if (typeof value === 'string') return [[key, value]]
      if (Array.isArray(value) && typeof value[0] === 'string') return [[key, value[0]]]

      return []
    }),
  )
