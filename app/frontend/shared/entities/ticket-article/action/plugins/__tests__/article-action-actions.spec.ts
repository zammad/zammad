// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { setupView } from '@tests/support/mock-user'
import { createTicketArticle, createTestArticleActions } from './utils'

describe('article action plugins - actions', () => {
  it('successfully returns available actions for agent', () => {
    setupView('agent')
    const { ticket } = defaultTicket()
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions).toHaveLength(1)
    expect(actions[0]).toMatchObject({
      name: 'changeVisibility',
    })
  })
})
