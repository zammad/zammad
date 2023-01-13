// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { mockPermissions } from '@tests/support/mock-permissions'
import { createTicketArticle, createTestArticleActions } from './utils'

describe('article action plugins - actions', () => {
  it('successfully returns available actions for agent', () => {
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions).toHaveLength(2)
    expect(actions[0]).toMatchObject({
      name: 'changeVisibility',
    })
    expect(actions[1]).toMatchObject({
      name: 'split',
      link: `/tickets/create?ticket_id=${ticket.id}&article_id=${article.id}`,
    })
  })
})
