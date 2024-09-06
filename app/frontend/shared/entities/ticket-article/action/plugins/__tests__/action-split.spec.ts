// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { setupView } from '#tests/support/mock-user.ts'

import {
  createTicketArticle,
  createTestArticleActions,
  createTicket,
} from './utils.ts'

describe('split action', () => {
  it('returns split link for agent with read access', () => {
    setupView('agent')
    const ticket = createTicket({
      policy: { agentReadAccess: true, update: false },
    })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article, 'desktop')

    expect(actions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          name: 'split',
          link: `/tickets/create?splitTicketArticleId=${encodeURIComponent(article.id)}`,
        }),
      ]),
    )
  })

  it('does not return split link for customer', () => {
    setupView('customer')
    const ticket = createTicket({ policy: { update: true } })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article, 'desktop')

    expect(actions).toEqual(
      expect.not.arrayContaining([
        expect.objectContaining({
          name: 'split',
          link: `/tickets/create?splitTicketArticleId=${encodeURIComponent(article.id)}`,
        }),
      ]),
    )
  })
})
