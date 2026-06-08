// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

export default <Operator>{
  name: 'contains one',
  label: __('contains one'),
  filterFields(attribute) {
    // Tags route through their dedicated FormKit `tags` field (per-keystroke
    // search, string-valued chips). Multi-value relation attributes (e.g.
    // ticket.state_id when declared as `multiselect`) fall back to a normal
    // multi-select; resolvers can still override `type` via
    // `operatorFilterProps['contains one'].type` (e.g. multi-treeselect).
    if (attribute.autocompleteFilterType) {
      return [
        {
          type: attribute.autocompleteFilterType,
          props: { clearable: true, multiple: true },
        },
      ]
    }
    return [{ type: 'select', props: { clearable: true, multiple: true } }]
  },
}
