// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import withinLastRelative from '../within-last-relative.ts'

const attribute = (overrides: Partial<FilterAttribute> = {}): FilterAttribute => ({
  name: 'ticket.created_at',
  label: 'Created at',
  operators: ['within last (relative)'],
  ...overrides,
})

describe('FieldFilterSelector - within last (relative) operator', () => {
  it('renders a count input (→ value) and a unit select (→ range)', () => {
    expect(withinLastRelative.filterFields(attribute({ attributeFieldType: 'date' }))).toEqual([
      {
        type: 'number',
        name: 'value',
        label: 'Value',
        props: { min: 1, number: 'integer' },
      },
      {
        type: 'select',
        name: 'range',
        label: 'Unit',
        props: {
          options: [
            { value: 'day', label: 'day(s)' },
            { value: 'week', label: 'week(s)' },
            { value: 'month', label: 'month(s)' },
            { value: 'year', label: 'year(s)' },
          ],
          clearable: false,
        },
      },
    ])
  })

  it('offers sub-day units (minute/hour) only for datetime attributes', () => {
    const fields = withinLastRelative.filterFields(attribute({ attributeFieldType: 'datetime' }))

    expect(fields?.[1]).toEqual({
      name: 'range',
      type: 'select',
      label: 'Unit',
      props: {
        options: [
          { value: 'minute', label: 'minute(s)' },
          { value: 'hour', label: 'hour(s)' },
          { value: 'day', label: 'day(s)' },
          { value: 'week', label: 'week(s)' },
          { value: 'month', label: 'month(s)' },
          { value: 'year', label: 'year(s)' },
        ],
        clearable: false,
      },
    })
  })

  it('seeds a default range unit so the row is valid before interaction', () => {
    expect(withinLastRelative.defaultEntryValues).toEqual({ range: 'day' })
  })
})
