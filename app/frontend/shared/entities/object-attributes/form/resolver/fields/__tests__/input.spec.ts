// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverInput } from '../input'

describe('FieldResovlerInput', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverInput({
      dataType: 'input',
      name: 'title',
      display: 'Title',
      dataOption: {
        type: 'text',
        maxlength: 100,
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Title',
      name: 'title',
      required: false,
      props: {
        maxlength: 100,
      },
      type: 'text',
      internal: true,
    })
  })
})
