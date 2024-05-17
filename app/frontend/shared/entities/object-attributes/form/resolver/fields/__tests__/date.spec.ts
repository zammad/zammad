// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverDate } from '../date.ts'

describe('FieldResolverDate', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverDate(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'date',
        name: 'date',
        display: 'Date',
        dataOption: {
          future: false,
          past: false,
          diff: 0,
          null: true,
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Date',
      name: 'date',
      required: false,
      props: {
        clearable: true,
      },
      type: 'date',
      internal: true,
    })
  })
})
