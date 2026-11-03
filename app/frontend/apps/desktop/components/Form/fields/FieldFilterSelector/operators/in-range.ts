// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

export default <Operator>{
  name: 'in range',
  label: __('in range'),
  filterFields(attribute) {
    const fieldType = attribute.attributeFieldType

    // The date range field's value is already the `[from, to]` array the backend `in range`
    // selector consumes, so no compound `list` is needed. `withTime` decides the value format,
    // so a datetime attribute keeps its ISO timestamps through the time panel.
    // `partialRange: false` commits only a complete range, never a half-selected `[from, null]`.
    if (fieldType === 'date' || fieldType === 'datetime') {
      const withTime = fieldType === 'datetime'

      return [{ type: 'daterange', props: { withTime, clearable: true, partialRange: false } }]
    }

    // Numbers have no native range field, so a `list` aggregates two bounds
    // into the `[min, max]` array (either bound blank-able; the all-blank case
    // is dropped upstream). Each child carries a label and a matching visible
    // placeholder; the selector renders the label screen-reader-only.
    return [
      {
        type: 'list',
        children: [
          {
            type: 'number',
            label: __('min'),
            placeholder: __('min'),
          },
          '-',
          {
            type: 'number',
            label: __('max'),
            placeholder: __('max'),
          },
        ],
      },
    ]
  },
}
