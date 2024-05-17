// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { setupView } from '#tests/support/mock-user.ts'

import {
  createTicketArticle,
  createTestArticleActions,
  createTicket,
} from './utils.ts'

describe('article action plugins - actions', () => {
  it('successfully returns available actions for agent', () => {
    setupView('agent')
    const ticket = createTicket()
    const article = createTicketArticle({
      type: {
        name: 'note',
      },
    })
    const actions = createTestArticleActions(ticket, article)
    expect(actions).toHaveLength(1)
    expect(actions[0]).toMatchObject({
      name: 'changeVisibility',
    })
  })
})
