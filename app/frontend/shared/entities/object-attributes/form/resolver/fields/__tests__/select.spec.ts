// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverSelect } from '../select.ts'

describe('FieldResolverSelect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
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
        clearable: false,
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
      },
      type: 'select',
      internal: true,
    })
  })

  it('should return the correct field attributes for relations', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'category',
      display: 'Category',
      dataOption: {
        historical_options: {},
        translate: true,
        options: {},
        relation: 'Group',
        belongs_to: 'group',
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Category',
      name: 'category',
      required: false,
      props: {
        historicalOptions: {},
        noOptionsLabelTranslation: false,
        clearable: false,
        options: [],
        belongsToObjectField: 'group',
        sorting: 'label',
      },
      relation: {
        type: 'Group',
      },
      type: 'select',
      internal: true,
    })
  })

  it('omits the options key for relation-typed attributes (options come from the form updater)', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'group_id',
      display: 'Group',
      dataOption: {
        translate: true,
        relation: 'Group',
        belongs_to: 'group',
      },
      isInternal: true,
    })

    expect(fieldResolver.getFilterOperatorProps()).toEqual({
      is: {
        noOptionsLabelTranslation: false,
        historicalOptions: undefined,
      },
    })
  })

  it('provides select filter fields for the is operator', () => {
    const fieldResolver = new FieldResolverSelect(EnumObjectManagerObjects.Ticket, {
      dataType: 'select',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
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
