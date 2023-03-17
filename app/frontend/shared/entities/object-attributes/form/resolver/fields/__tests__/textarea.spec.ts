// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverTextarea } from '../textarea'

describe('FieldResolverTextarea', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverTextarea({
      dataType: 'input',
      name: 'text',
      display: 'Text',
      dataOption: {
        maxlength: 100,
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Text',
      name: 'text',
      required: false,
      props: {
        maxlength: 100,
      },
      type: 'textarea',
      internal: true,
    })
  })
})
