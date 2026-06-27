// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverMultiselect } from '../multiselect.ts'

describe('FieldResolverMultiselect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverMultiselect(EnumObjectManagerObjects.Ticket, {
      dataType: 'multiselect',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
        nulloption: true,
        options: {
          a: 'a',
          b: 'b',
          c: 'c',
        },
        historical_options: {
          a: 'a',
          b: 'b',
          c: 'c',
          d: 'd',
        },
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Category',
      name: 'category',
      required: false,
      props: {
        noOptionsLabelTranslation: false,
        clearable: true,
        options: [
          {
            label: 'a',
            value: 'a',
          },
          {
            label: 'b',
            value: 'b',
          },
          {
            label: 'c',
            value: 'c',
          },
        ],
        historicalOptions: {
          a: 'a',
          b: 'b',
          c: 'c',
          d: 'd',
        },
        multiple: true,
        // Object-keyed options need label sorting (no stable iteration order).
        sorting: 'label',
      },
      type: 'select',
      internal: true,
    })
  })

  it('provides `contains one` filter operator props', () => {
    // Multi-value selects emit `contains one` (not `is`) so the operator name
    // matches the existing overview / trigger condition vocabulary and the
    // backend ES + SQL selector wiring for multi-value attributes.
    const fieldResolver = new FieldResolverMultiselect(EnumObjectManagerObjects.Ticket, {
      dataType: 'multiselect',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
        nulloption: true,
        options: {
          a: 'a',
          b: 'b',
        },
        historical_options: {
          a: 'a',
          b: 'b',
        },
      },
      isInternal: true,
    })

    expect(fieldResolver.getFieldFilterOperators()).toEqual(['contains one'])

    expect(fieldResolver.getFilterOperatorProps()).toEqual({
      'contains one': {
        noOptionsLabelTranslation: false,
        options: [
          { label: 'a', value: 'a' },
          { label: 'b', value: 'b' },
        ],
        historicalOptions: {
          a: 'a',
          b: 'b',
        },
        sorting: 'label',
      },
    })
  })
})
