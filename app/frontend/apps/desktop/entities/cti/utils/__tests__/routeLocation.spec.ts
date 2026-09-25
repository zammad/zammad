// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { callerTicketCreateRoute, customerTicketCreateRoute } from '../routeLocation.ts'

const log = { from: '4912345678', fromPretty: '+49 12345678' }

describe('customerTicketCreateRoute', () => {
  it('carries the customer by id', () => {
    expect(customerTicketCreateRoute({ internalId: 2 })).toEqual({
      name: 'TicketCreate',
      query: { customer_id: 2 },
    })
  })
})

describe('callerTicketCreateRoute', () => {
  it('carries a detected customer by id', () => {
    expect(callerTicketCreateRoute(log, { internalId: 2 })).toEqual({
      name: 'TicketCreate',
      query: { customer_id: 2 },
    })
  })

  it('carries the number of an unknown caller, formatted for reading', () => {
    expect(callerTicketCreateRoute(log)).toEqual({
      name: 'TicketCreate',
      query: { customer_phone: '+49 12345678' },
    })
  })
})
