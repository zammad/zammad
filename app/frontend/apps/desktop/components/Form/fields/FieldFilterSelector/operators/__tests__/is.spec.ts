// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import is from '../is.ts'

const attribute = (overrides: Partial<FilterAttribute> = {}): FilterAttribute => ({
  name: 'ticket.state_id',
  label: 'State',
  operators: ['is'],
  ...overrides,
})

describe('FieldFilterSelector - is operator', () => {
  it('renders a multi-select for plain relation attributes', () => {
    expect(is.filterFields(attribute())).toEqual([
      { type: 'select', props: { clearable: true, multiple: true, delay: 400 } },
    ])
  })

  it.each([
    { name: 'ticket.customer_id', autocompleteFilterType: 'customer' },
    { name: 'ticket.organization_id', autocompleteFilterType: 'organization' },
    { name: 'ticket.owner_id', autocompleteFilterType: 'agent' },
  ])(
    'renders the $autocompleteFilterType autocomplete for $name',
    ({ name, autocompleteFilterType }) => {
      expect(is.filterFields(attribute({ name, autocompleteFilterType }))).toEqual([
        { type: autocompleteFilterType, props: { clearable: true, multiple: true, delay: 400 } },
      ])
    },
  )
})
