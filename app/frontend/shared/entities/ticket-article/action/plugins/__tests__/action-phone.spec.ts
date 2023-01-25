// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { setupView } from '@tests/support/mock-user'
import { createTestArticleTypes } from './utils'

describe('phone type', () => {
  it('customer cannot use phone type', () => {
    setupView('customer')
    const { ticket } = defaultTicket()
    const actions = createTestArticleTypes(ticket)
    expect(actions.find((a) => a.value === 'phone')).toBeUndefined()
  })

  it('agents can use phone type', () => {
    setupView('agent')
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const actions = createTestArticleTypes(ticket)
    expect(actions.find((a) => a.value === 'phone')).toBeDefined()
  })
})
