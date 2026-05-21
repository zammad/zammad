// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

export default <Operator>{
  name: 'is',
  label: __('is'),
  filterFields(attribute) {
    if (attribute.autocompleteFilterType) {
      // TODO: end-to-end behavior of autocomplete inputs inside the filter
      // selector is not yet validated — the row value shape and per-keystroke
      // query wiring still need verification. Hide the operator until ready.
      // See follow-up of #1317.
      return null
    }
    return [{ type: 'select', props: { clearable: true, multiple: true } }]
  },
}
