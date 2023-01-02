// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverSelect } from '../select'

describe('FieldResolverSelect', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverSelect({
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
      },
      type: 'select',
      internal: true,
    })
  })
})
