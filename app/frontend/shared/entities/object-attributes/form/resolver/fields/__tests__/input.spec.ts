// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverInput } from '../input.ts'

describe('FieldResovlerInput', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverInput(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'input',
        name: 'title',
        display: 'Title',
        dataOption: {
          type: 'text',
          maxlength: 100,
        },
        isInternal: true,
      },
    )

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
