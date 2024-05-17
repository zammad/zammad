// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverInteger } from '../integer.ts'

describe('FieldResovlerInput', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverInteger(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'integer',
        name: 'count',
        display: 'Count',
        dataOption: {
          min: 1,
          max: 100,
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Count',
      name: 'count',
      required: false,
      props: {
        min: 1,
        max: 100,
      },
      type: 'number',
      internal: true,
    })
  })
})
