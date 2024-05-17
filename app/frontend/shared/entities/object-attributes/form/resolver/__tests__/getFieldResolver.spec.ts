// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import getFieldResolver from '../getFieldResolver.ts'

describe('object attribute resolver available', () => {
  it('should return the correct field resolver', () => {
    const fieldResolver = getFieldResolver(EnumObjectManagerObjects.Ticket, {
      dataType: 'input',
      name: 'title',
      display: 'Title',
      dataOption: {
        type: 'text',
        maxlength: 100,
        null: true,
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Title',
      name: 'title',
      props: {
        maxlength: 100,
      },
      type: 'text',
      required: false,
      internal: true,
    })
  })
})
