// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

export default <Operator>{
  name: 'in range',
  label: __('in range'),
  filterFields() {
    // A `list` aggregates its two number children into a `[min, max]` array —
    // the shape the backend `in range` selector consumes (either bound
    // blank-able; the all-blank case is dropped upstream). Each child is a
    // number field with a label and a matching visible placeholder; the
    // selector renders the label screen-reader-only.
    return [
      {
        type: 'list',
        children: [
          {
            type: 'number',
            label: __('min'),
            placeholder: __('min'),
            props: { delay: 500 },
          },
          '-',
          {
            type: 'number',
            label: __('max'),
            placeholder: __('max'),
            props: { delay: 500 },
          },
        ],
      },
    ]
  },
}
