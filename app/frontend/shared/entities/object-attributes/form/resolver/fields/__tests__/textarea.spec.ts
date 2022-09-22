// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Text',
      name: 'text',
      props: {
        maxlength: 100,
      },
      type: 'textarea',
    })
  })
})
