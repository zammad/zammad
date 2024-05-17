// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverTag } from '../tag.ts'

describe('FieldResolverTag', () => {
  it('should return the correct field attributes', () => {
    mockApplicationConfig({
      tag_new: true,
    })

    const fieldResolver = new FieldResolverTag(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'tag',
        name: 'tag',
        display: 'Tag',
        dataOption: {
          type: 'text',
          null: true,
          translate: false,
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Tag',
      name: 'tag',
      required: false,
      props: {
        canCreate: true,
      },
      type: 'tags',
      internal: true,
    })
  })
})
