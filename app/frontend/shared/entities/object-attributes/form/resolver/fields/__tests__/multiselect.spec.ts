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
      },
      type: 'select',
      internal: true,
    })
  })

  it('provides is filter fields with multiple enabled', () => {
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

    expect(fieldResolver.getFilterOperatorProps()).toEqual({
      is: {
        noOptionsLabelTranslation: false,
        options: [
          { label: 'a', value: 'a' },
          { label: 'b', value: 'b' },
        ],
        historicalOptions: {
          a: 'a',
          b: 'b',
        },
      },
    })
  })
})
