// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverBoolean } from '../boolean'

describe('FieldResolverBoolean', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverBoolean({
      dataType: 'boolean',
      name: 'correct',
      display: 'Correct?',
      dataOption: {
        options: { false: 'no', true: 'yes' },
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Correct?',
      name: 'correct',
      required: false,
      props: {
        options: [
          {
            label: 'yes',
            value: true,
          },
          {
            label: 'no',
            value: false,
          },
        ],
      },
      type: 'select',
      internal: true,
    })
  })
})
