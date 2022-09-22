// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Body',
      name: 'body',
      props: {},
      type: 'editor',
    })
  })
})
