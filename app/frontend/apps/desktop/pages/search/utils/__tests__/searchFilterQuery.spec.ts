// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import {
  decodeFilters,
  encodeFilters,
  isFilterParamKey,
} from '#desktop/pages/search/utils/searchFilterQuery.ts'

const filterAttributes: FilterAttribute[] = [
  {
    name: 'ticket.title',
    label: 'Title',
    operators: ['ticket.matches', 'ticket.is'],
  },
  {
    name: 'ticket.ticket_number',
    label: '#',
    operators: ['ticket.is'],
  },
]

describe('searchFilterQuery', () => {
  describe('encode', () => {
    it('serializes filters into dot-path triplets', () => {
      const result = encodeFilters([
        { name: 'ticket.title', operator: 'ticket.matches', value: 'zammad' },
        { name: 'ticket.ticket_number', operator: 'ticket.is', value: '3' },
      ])

      expect(result).toEqual({
        'filter.0.name': 'ticket.title',
        'filter.0.operator': 'ticket.matches',
        'filter.0.value': 'zammad',
        'filter.1.name': 'ticket.ticket_number',
        'filter.1.operator': 'ticket.is',
        'filter.1.value': '3',
      })
    })

    it('skips entries missing name/operator/value and re-indexes the rest', () => {
      const result = encodeFilters([
        { name: 'ticket.title', operator: 'ticket.matches', value: '' },
        { name: '', operator: 'ticket.is', value: 'x' },
        { name: 'ticket.title', operator: '', value: 'x' },
        { name: 'ticket.ticket_number', operator: 'ticket.is', value: '3' },
      ])

      expect(result).toEqual({
        'filter.0.name': 'ticket.ticket_number',
        'filter.0.operator': 'ticket.is',
        'filter.0.value': '3',
      })
    })

    it('encodes nested object values into a dotted subtree', () => {
      const result = encodeFilters([
        {
          name: 'ticket.created_at',
          operator: 'ticket.between',
          value: { from: '2026-01-01', to: '2026-12-31' },
        },
      ])

      expect(result).toEqual({
        'filter.0.name': 'ticket.created_at',
        'filter.0.operator': 'ticket.between',
        'filter.0.value.from': '2026-01-01',
        'filter.0.value.to': '2026-12-31',
      })
    })

    it('coerces numeric and boolean values to strings', () => {
      const result = encodeFilters([
        { name: 'ticket.ticket_number', operator: 'ticket.is', value: 3 },
        { name: 'ticket.active', operator: 'ticket.is', value: true },
      ])

      expect(result).toEqual({
        'filter.0.name': 'ticket.ticket_number',
        'filter.0.operator': 'ticket.is',
        'filter.0.value': '3',
        'filter.1.name': 'ticket.active',
        'filter.1.operator': 'ticket.is',
        'filter.1.value': 'true',
      })
    })
  })

  describe('decode', () => {
    it('parses dot-path triplets back into filter entries', () => {
      const result = decodeFilters(
        {
          entity: 'Ticket',
          'filter.0.name': 'ticket.title',
          'filter.0.operator': 'ticket.matches',
          'filter.0.value': 'zammad',
          'filter.1.name': 'ticket.ticket_number',
          'filter.1.operator': 'ticket.is',
          'filter.1.value': '3',
        },
        filterAttributes,
      )

      expect(result).toEqual([
        { name: 'ticket.title', operator: 'ticket.matches', value: 'zammad' },
        { name: 'ticket.ticket_number', operator: 'ticket.is', value: '3' },
      ])
    })

    it('drops incomplete entries and unknown attributes/operators', () => {
      const result = decodeFilters(
        {
          'filter.0.name': 'ticket.title',
          'filter.0.operator': 'ticket.matches',
          'filter.0.value': '',
          'filter.1.name': 'ticket.unknown',
          'filter.1.operator': 'ticket.matches',
          'filter.1.value': 'ignored',
          'filter.2.name': 'ticket.ticket_number',
          'filter.2.operator': 'ticket.matches',
          'filter.2.value': 'ignored',
          'filter.3.name': 'ticket.ticket_number',
          'filter.3.operator': 'ticket.is',
          'filter.3.value': '5',
        },
        filterAttributes,
      )

      expect(result).toEqual([{ name: 'ticket.ticket_number', operator: 'ticket.is', value: '5' }])
    })

    it('returns parsed entries unchanged when no attribute schema is supplied', () => {
      const result = decodeFilters({
        'filter.0.name': 'anything',
        'filter.0.operator': 'whatever',
        'filter.0.value': 'value',
      })

      expect(result).toEqual([{ name: 'anything', operator: 'whatever', value: 'value' }])
    })

    it('sorts entries by their index', () => {
      const result = decodeFilters({
        'filter.2.name': 'ticket.ticket_number',
        'filter.2.operator': 'ticket.is',
        'filter.2.value': 'second',
        'filter.0.name': 'ticket.title',
        'filter.0.operator': 'ticket.matches',
        'filter.0.value': 'first',
      })

      expect(result.map((entry) => entry.value)).toEqual(['first', 'second'])
    })

    it('takes the first element of array query values (vue-router multi-value keys)', () => {
      const result = decodeFilters({
        'filter.0.name': ['ticket.title'],
        'filter.0.operator': ['ticket.matches'],
        'filter.0.value': ['zammad'],
      })

      expect(result).toEqual([
        { name: 'ticket.title', operator: 'ticket.matches', value: 'zammad' },
      ])
    })

    it('decodes unicode values from restored query records', () => {
      const result = decodeFilters({
        'filter.0.name': 'ticket.title',
        'filter.0.operator': 'ticket.matches',
        'filter.0.value': '%F0%9F%8E%93',
      })

      expect(result).toEqual([{ name: 'ticket.title', operator: 'ticket.matches', value: '🎓' }])
    })

    it('coerces autocomplete-relation values from strings back to integer IDs', () => {
      const result = decodeFilters(
        {
          'filter.0.name': 'ticket.owner_id',
          'filter.0.operator': 'ticket.is',
          'filter.0.value': ['7', '42'],
        },
        [
          {
            name: 'ticket.owner_id',
            label: 'Owner',
            operators: ['ticket.is'],
            relation: 'User',
            autocompleteFilterType: 'agent',
          },
        ],
      )

      expect(result).toEqual([{ name: 'ticket.owner_id', operator: 'ticket.is', value: [7, 42] }])
    })

    it('coerces a single autocomplete-relation value back to an integer ID', () => {
      const result = decodeFilters(
        {
          'filter.0.name': 'ticket.customer_id',
          'filter.0.operator': 'ticket.is',
          'filter.0.value': '7',
        },
        [
          {
            name: 'ticket.customer_id',
            label: 'Customer',
            operators: ['ticket.is'],
            relation: 'User',
            autocompleteFilterType: 'customer',
          },
        ],
      )

      expect(result).toEqual([{ name: 'ticket.customer_id', operator: 'ticket.is', value: 7 }])
    })

    it('keeps tag autocomplete values as strings even when they look numeric', () => {
      // Tags are referenced by name, not ID — a tag literally named "5" must
      // round-trip as the string "5" so the ES `terms` query matches it.
      const result = decodeFilters(
        {
          'filter.0.name': 'ticket.tags',
          'filter.0.operator': 'ticket.contains one',
          'filter.0.value': ['urgent', '5'],
        },
        [
          {
            name: 'ticket.tags',
            label: 'Tags',
            operators: ['ticket.contains one'],
            autocompleteFilterType: 'tags',
          },
        ],
      )

      expect(result).toEqual([
        { name: 'ticket.tags', operator: 'ticket.contains one', value: ['urgent', '5'] },
      ])
    })
  })

  describe('isFilterParamKey', () => {
    it('matches keys in the filter namespace', () => {
      expect(isFilterParamKey('filter.0.name')).toBe(true)
      expect(isFilterParamKey('filter.12.operator')).toBe(true)
      expect(isFilterParamKey('filter.0.value.from')).toBe(true)
    })

    it('does not match keys outside the filter namespace', () => {
      expect(isFilterParamKey('entity')).toBe(false)
      expect(isFilterParamKey('ticket.title')).toBe(false)
      expect(isFilterParamKey('filtersomething')).toBe(false)
    })
  })

  describe('decode of nested values', () => {
    it('parses a dotted value subtree back into a nested object', () => {
      const result = decodeFilters({
        'filter.0.name': 'ticket.created_at',
        'filter.0.operator': 'ticket.between',
        'filter.0.value.from': '2026-01-01',
        'filter.0.value.to': '2026-12-31',
      })

      expect(result).toEqual([
        {
          name: 'ticket.created_at',
          operator: 'ticket.between',
          value: { from: '2026-01-01', to: '2026-12-31' },
        },
      ])
    })
  })
})
