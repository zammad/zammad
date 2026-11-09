// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverRichtext } from '../richtext.ts'

describe('FieldResolverRichtext', () => {
  it('should return the correct field attributes with maxlength', () => {
    const fieldResolver = new FieldResolverRichtext(EnumObjectManagerObjects.Ticket, {
      dataType: 'richtext',
      name: 'body',
      display: 'Body',
      dataOption: {
        type: 'richtext',
        maxlength: 150_000,
        upload: true,
        rows: 8,
        null: true,
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Body',
      name: 'body',
      required: false,
      props: {
        extensionSet: 'basic',
        meta: {
          footer: {
            maxlength: 150_000,
          },
        },
      },
      type: 'editor',
      internal: true,
    })
  })

  it('should return field attributes without maxlength when not provided', () => {
    const fieldResolver = new FieldResolverRichtext(EnumObjectManagerObjects.Ticket, {
      dataType: 'richtext',
      name: 'body',
      display: 'Body',
      dataOption: {
        type: 'richtext',
        upload: true,
        rows: 8,
        null: true,
      },
      isInternal: true,
    })

    const attributes = fieldResolver.fieldAttributes()

    expect(attributes).toEqual({
      label: 'Body',
      name: 'body',
      required: false,
      props: {
        extensionSet: 'basic',
        meta: {
          footer: {},
        },
      },
      type: 'editor',
      internal: true,
    })
  })
})
