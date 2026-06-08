// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

export default <Operator>{
  name: 'is',
  label: __('is'),
  filterFields(attribute) {
    // Autocomplete-style relations (customer / organization / agent) are
    // rendered by their dedicated FormKit field — the wrapper handles the
    // per-keystroke query, option building, and value shape (array of
    // internal IDs) the backend `is` operator already accepts.
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
