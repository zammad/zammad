// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverTreeselect } from '../treeselect.ts'

describe('FieldResolverTreeselect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverTreeselect(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'tree_select',
        name: 'category',
        display: 'Category',
        dataOption: {
          options: [
            {
              name: 'Category 1',
              value: 'Category 1',
              children: [
                {
                  name: 'Category 1.1',
                  value: 'Category 1::Category 1.1',
                },
              ],
            },
            {
              name: 'Category 2',
              value: 'Category 2',
            },
          ],
          translate: true,
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Category',
      name: 'category',
      required: false,
      props: {
        noOptionsLabelTranslation: false,
        clearable: false,
        options: [
          {
            label: 'Category 1',
            value: 'Category 1',
            children: [
              {
                label: 'Category 1.1',
                value: 'Category 1::Category 1.1',
              },
            ],
          },
          {
            label: 'Category 2',
            value: 'Category 2',
          },
        ],
      },
      type: 'treeselect',
      internal: true,
    })
  })

  it('should return the correct field attributes for relations', () => {
    const fieldResolver = new FieldResolverTreeselect(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'treeselect',
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
      },
    )

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
        // TODO: Check if this is also good for treeselect
        sorting: 'label',
      },
      relation: {
        type: 'Group',
      },
      type: 'treeselect',
      internal: true,
    })
  })
})
