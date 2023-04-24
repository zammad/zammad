// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '#mobile/pages/ticket/__tests__/mocks/detail-view.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { createTestArticleTypes } from './utils.ts'

describe('web type', () => {
  it('customer does get web type', () => {
    mockPermissions(['ticket.customer'])
    const { ticket } = defaultTicket()

    const types = createTestArticleTypes(ticket)

    expect(types).toContainEqual(expect.objectContaining({ value: 'web' }))
  })

  it('agent does not get web type', () => {
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()

    const types = createTestArticleTypes(ticket)

    expect(types).not.toContainEqual(expect.objectContaining({ value: 'web' }))
  })
})
