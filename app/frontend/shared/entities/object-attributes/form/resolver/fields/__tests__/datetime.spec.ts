// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { FieldResolverDateTime } from '../datetime.ts'

const now = new Date('2026-02-08T12:00:00Z')

describe('FieldResolverDateTime', () => {
  beforeEach(() => {
    vi.useFakeTimers().setSystemTime(now)
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('should return the correct field attributes', () => {
    const fieldResolver = new FieldResolverDateTime(EnumObjectManagerObjects.Ticket, {
      dataType: 'datetime',
      name: 'datetime',
      display: 'DateTime',
      dataOption: {
        future: false,
        past: false,
        diff: 1440, // 24 hours
        null: true,
        translate: true,
        permission: 'ticket.agent',
      },
      isInternal: true,
    })

    expect(fieldResolver.fieldAttributes()).toEqual({
      label: 'DateTime',
      name: 'datetime',
      required: false,
      props: {
        clearable: true,
        futureOnly: true,
        pastOnly: true,
      },
      type: 'datetime',
      internal: true,
      value: '2026-02-09T12:00:00Z',
    })
  })
})
