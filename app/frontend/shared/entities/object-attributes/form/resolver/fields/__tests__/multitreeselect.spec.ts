// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverMultiTreeselect } from '../multitreeselect.ts'

describe('FieldResolverMultiTreeselect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverMultiTreeselect(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'multi_tree_select',
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
        multiple: true,
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
})
