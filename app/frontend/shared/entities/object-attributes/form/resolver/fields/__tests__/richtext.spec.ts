// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FieldResolverRichtext } from '../richtext'

describe('FieldResolverRichtext', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverRichtext({
      dataType: 'richtext',
      name: 'body',
      display: 'Body',
      dataOption: {
        // TODO ...
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Body',
      name: 'body',
      required: false,
      props: {},
      type: 'editor',
      internal: true,
    })
  })
})
