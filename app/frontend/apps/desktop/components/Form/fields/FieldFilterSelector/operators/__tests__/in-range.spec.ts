// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import inRange from '../in-range.ts'

const attribute = (overrides: Partial<FilterAttribute> = {}): FilterAttribute => ({
  name: 'ticket.escalation_count',
  label: 'Escalation count',
  operators: ['in range'],
  ...overrides,
})

describe('FieldFilterSelector - in range operator', () => {
  it('renders a list whose two number children aggregate into the [min, max] array', () => {
    expect(inRange.filterFields(attribute())).toEqual([
      {
        type: 'list',
        children: [
          {
            type: 'number',
            label: 'min',
            placeholder: 'min',
          },
          '-',
          {
            type: 'number',
            label: 'max',
            placeholder: 'max',
          },
        ],
      },
    ])
  })

  it.each([
    ['date', false],
    ['datetime', true],
  ])(
    'renders a single date range field for %s, with a time for datetime',
    (fieldType, withTime) => {
      expect(inRange.filterFields(attribute({ attributeFieldType: fieldType }))).toEqual([
        { type: 'daterange', props: { withTime, clearable: true, partialRange: false } },
      ])
    },
  )
})
