// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createTestArticleTypes, createTicket } from './utils.ts'

describe('web type', () => {
  it('customer does get web type', () => {
    mockPermissions(['ticket.customer'])
    const ticket = createTicket()

    const types = createTestArticleTypes(ticket)

    expect(types).toContainEqual(expect.objectContaining({ value: 'web' }))
  })

  it('agent does not get web type', () => {
    mockPermissions(['ticket.agent'])
    const ticket = createTicket()

    const types = createTestArticleTypes(ticket)

    expect(types).not.toContainEqual(expect.objectContaining({ value: 'web' }))
  })
})
