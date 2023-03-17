// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverTag } from '../tag'

describe('FieldResolverTag', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverTag({
      dataType: 'tag',
      name: 'tag',
      display: 'Tag',
      dataOption: {
        // TODO ...
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Tag',
      name: 'tag',
      required: false,
      props: {},
      type: 'tags',
      internal: true,
    })
  })
})
