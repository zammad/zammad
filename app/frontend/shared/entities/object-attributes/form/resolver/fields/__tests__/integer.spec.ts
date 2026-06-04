// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverInteger } from '../integer.ts'

describe('FieldResolverInteger', () => {
  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverInteger(EnumObjectManagerObjects.Ticket, {
      dataType: 'integer',
      name: 'count',
      display: 'Count',
      dataOption: {
        min: 1,
        max: 100,
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'Count',
      name: 'count',
      required: false,
      props: {
        min: 1,
        max: 100,
        number: 'integer',
      },
      type: 'number',
      internal: true,
    })
  })

  it('exposes the `in range` operator for advanced search filters', () => {
    const fieldResolver = new FieldResolverInteger(EnumObjectManagerObjects.Ticket, {
      dataType: 'integer',
      name: 'count',
      display: 'Count',
      dataOption: {},
      isInternal: true,
    })

    expect(fieldResolver.getFieldFilterOperators()).toEqual(['in range'])
  })
})
