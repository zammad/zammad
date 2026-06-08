// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import containsOne from '../contains-one.ts'

const attribute = (overrides: Partial<FilterAttribute> = {}): FilterAttribute => ({
  name: 'ticket.tags',
  label: 'Tags',
  operators: ['contains one'],
  autocompleteFilterType: 'tags',
  ...overrides,
})

describe('FieldFilterSelector - contains one operator', () => {
  it('renders the tags autocomplete', () => {
    expect(containsOne.filterFields(attribute())).toEqual([
      { type: 'tags', props: { clearable: true, multiple: true } },
    ])
  })

  it('renders a multi-select for plain multiselect / multi-treeselect attributes', () => {
    // No autocomplete type → multi-value relation attribute (e.g.
    // `multiselect` ticket.state_id). The resolver can still override the
    // rendered `type` via operatorFilterProps (multi-treeselect does so).
    expect(containsOne.filterFields(attribute({ autocompleteFilterType: undefined }))).toEqual([
      { type: 'select', props: { clearable: true, multiple: true } },
    ])
  })
})
