// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'

import { dropEmptyFilterValues } from '../useSearchAdvancedFilters.ts'

describe('dropEmptyFilterValues', () => {
  it('drops entries with null, undefined, or empty-string value', () => {
    const filters: FilterSelectorEntry[] = [
      { name: 'ticket.title', operator: 'matches', value: '' },
      { name: 'ticket.number', operator: 'matches', value: null },
      { name: 'ticket.subject', operator: 'matches', value: undefined },
      { name: 'ticket.body', operator: 'matches', value: 'foo' },
    ]

    expect(dropEmptyFilterValues(filters).map((entry) => entry.name)).toEqual(['ticket.body'])
  })

  it('drops entries whose value is an empty array (e.g. a multi-select `is` filter after deselect)', () => {
    const filters: FilterSelectorEntry[] = [
      { name: 'ticket.group_id', operator: 'is', value: [] },
      { name: 'ticket.state_id', operator: 'is', value: [1, 2] },
    ]

    expect(dropEmptyFilterValues(filters).map((entry) => entry.name)).toEqual(['ticket.state_id'])
  })
})
