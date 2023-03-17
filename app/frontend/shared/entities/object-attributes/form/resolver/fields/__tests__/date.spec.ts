// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverDate } from '../date'

describe('FieldResolverDate', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverDate({
      dataType: 'date',
      name: 'date',
      display: 'Date',
      dataOption: {
        // TODO ...
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Date',
      name: 'date',
      required: false,
      props: {},
      type: 'date',
      internal: true,
    })
  })
})
