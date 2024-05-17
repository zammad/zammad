// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverDateTime } from '../datetime.ts'

describe('FieldResolverDateTime', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverDateTime(
      EnumObjectManagerObjects.Ticket,
      {
        dataType: 'datetime',
        name: 'datetime',
        display: 'DateTime',
        dataOption: {
          future: true,
          past: false,
          diff: null,
          null: true,
          translate: true,
          permission: 'ticket.agent',
        },
        isInternal: true,
      },
    )

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'DateTime',
      name: 'datetime',
      required: false,
      props: {
        clearable: true,
      },
      type: 'datetime',
      internal: true,
    })
  })
})
