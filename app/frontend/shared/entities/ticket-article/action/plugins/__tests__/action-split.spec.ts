// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { mockPermissions } from '@tests/support/mock-permissions'
import { createTicketArticle, createTestArticleActions } from './utils'

describe('split action', () => {
  it('returns split for customer and editable ticket', () => {
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'split')).toBeDefined()
  })

  it.each(['ticket.customer', 'ticket.agent'])(
    "doesn't return split for non-editable tickets %s",
    (permission) => {
      mockPermissions([permission])
      const { ticket } = defaultTicket()
      ticket.policy.update = false
      const article = createTicketArticle()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'split')).toBeUndefined()
    },
  )

  it("doesn't return split for customer", () => {
    mockPermissions(['ticket.customer'])
    const { ticket } = defaultTicket()
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'split')).toBeUndefined()
  })
})
