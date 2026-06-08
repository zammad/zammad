// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

// Selectable units for the relative `range`, mirroring the legacy ticket
// selector.
const RANGE_OPTIONS = [
  { value: 'minute', label: __('minute(s)') },
  { value: 'hour', label: __('hour(s)') },
  { value: 'day', label: __('day(s)') },
  { value: 'week', label: __('week(s)') },
  { value: 'month', label: __('month(s)') },
  { value: 'year', label: __('year(s)') },
]

// `date` attributes carry no sub-day resolution, so these units are dropped for
// them (offered for `datetime` only).
const SKIP_RANGE_OPTIONS_FOR_DATE = new Set(['minute', 'hour'])

export default <Operator>{
  name: 'within last (relative)',
  label: __('within last (relative)'),
  // Seed a sensible unit so `range` is valid before the user touches the row;
  // the count (`value`) stays blank and keeps the row out of the query until
  // entered.
  defaultEntryValues: { range: 'day' },
  filterFields(attribute) {
    const options =
      attribute.attributeFieldType === 'datetime'
        ? RANGE_OPTIONS
        : RANGE_OPTIONS.filter((option) => !SKIP_RANGE_OPTIONS_FOR_DATE.has(option.value))

    // Two siblings stored at the same level — the count → `value`, the unit →
    // `range` — matching the shape the backend relative operator consumes.
    return [
      {
        type: 'number',
        name: 'value',
        label: __('Value'),
        props: { min: 1, number: 'integer' },
      },
      {
        type: 'select',
        name: 'range',
        label: __('Unit'),
        props: { options, clearable: false },
      },
    ]
  },
}
