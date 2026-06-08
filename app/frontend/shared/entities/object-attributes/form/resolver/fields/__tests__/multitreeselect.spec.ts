// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverMultiTreeselect } from '../multitreeselect.ts'

describe('FieldResolverMultiTreeselect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverMultiTreeselect(EnumObjectManagerObjects.Ticket, {
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
    })

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

  it('provides `contains one` filter operator props with type=treeselect', () => {
    // Multi-tree-select switches the operator name (inherits `contains one`
    // from FieldResolverMultiselect's pattern) and the rendered field type
    // (`treeselect` instead of plain `select`).
    const fieldResolver = new FieldResolverMultiTreeselect(EnumObjectManagerObjects.Ticket, {
      dataType: 'multi_tree_select',
      name: 'category',
      display: 'Category',
      dataOption: {
        translate: true,
        options: [{ name: 'A', value: 'a' }],
      },
      isInternal: true,
    })

    expect(fieldResolver.getFieldFilterOperators()).toEqual(['contains one'])

    expect(fieldResolver.getFilterOperatorProps()).toEqual({
      'contains one': {
        type: 'treeselect',
        noOptionsLabelTranslation: false,
        options: [{ label: 'A', value: 'a' }],
        historicalOptions: undefined,
      },
    })
  })
})
