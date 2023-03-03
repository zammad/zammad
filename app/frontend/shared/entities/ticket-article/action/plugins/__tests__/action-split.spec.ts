// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketView } from '@shared/entities/ticket/types'
import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { setupView } from '@tests/support/mock-user'
import { createTicketArticle, createTestArticleActions } from './utils'

describe('split action', () => {
  it('returns split for customer and editable ticket', () => {
    setupView('agent')
    const { ticket } = defaultTicket({ update: true })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'split')).toBeDefined()
  })

  const views: TicketView[] = ['agent', 'customer']
  it.each(views)("doesn't return split for non-editable tickets %s", (view) => {
    setupView(view)
    const { ticket } = defaultTicket({ update: false })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'split')).toBeUndefined()
  })

  it("doesn't return split for customer", () => {
    setupView('customer')
    const { ticket } = defaultTicket({ update: true })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'split')).toBeUndefined()
  })
})
