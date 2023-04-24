// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '#mobile/pages/ticket/__tests__/mocks/detail-view.ts'
import type { TicketView } from '#shared/entities/ticket/types.ts'
import { setupView } from '#tests/support/mock-user.ts'
import { createTicketArticle, createTestArticleActions } from './utils.ts'

describe('changeVisibility action', () => {
  it('returns changeVisibility for customer and editable ticket', () => {
    setupView('agent')
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'changeVisibility')).toBeDefined()
  })

  const views: TicketView[] = ['agent', 'customer']
  it.each(views)(
    "doesn't return changeVisibility for non-editable tickets %s",
    (view) => {
      setupView(view)
      const { ticket } = defaultTicket()
      ticket.policy.update = false
      const article = createTicketArticle()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'changeVisibility')).toBeUndefined()
    },
  )

  it("doesn't return changeVisibility for customer", () => {
    setupView('customer')
    const { ticket } = defaultTicket()
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'changeVisibility')).toBeUndefined()
  })
})
