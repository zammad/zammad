// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverMultiselect } from '../multiselect'

describe('FieldResolverMultiselect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverMultiselect({
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
        multiple: true,
      },
      type: 'select',
      internal: true,
    })
  })
})
