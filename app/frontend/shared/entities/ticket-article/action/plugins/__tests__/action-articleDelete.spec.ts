// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defaultTicket } from '@mobile/pages/ticket/__tests__/mocks/detail-view'
import { mockPermissions } from '@tests/support/mock-permissions'
import { mockApplicationConfig } from '@tests/support/mock-applicationConfig'
import { createTicketArticle, createTestArticleActions } from './utils'

const createDeletableArticle = (
  userId = '123',
  isCommunication = false,
  isInternal = true,
  createdAt: Date = new Date(),
) => {
  const article = createTicketArticle()
  article.createdBy!.id = userId
  article.type!.communication = isCommunication
  article.internal = isInternal
  article.createdAt = createdAt.toISOString()
  return article
}

describe('article delete action', () => {
  it('returns article delete for editable ticket', () => {
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createDeletableArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeDefined()
  })

  it('does not return article delete for article created by another user', () => {
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createDeletableArticle('456')
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })

  it('does not return article delete for communication article', () => {
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createDeletableArticle('123', true, false)
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })

  it('returns article delete for internal communication article', () => {
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createDeletableArticle('123', true, true)
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeDefined()
  })

  it('does not return article delete for old article', () => {
    mockApplicationConfig({ ui_ticket_zoom_article_delete_timeframe: 600 })
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createDeletableArticle(
      '123',
      false,
      false,
      new Date('1999 12 31'),
    )
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })

  it('returns article delete for old article if delete timeframe is disabled', () => {
    mockApplicationConfig({ ui_ticket_zoom_article_delete_timeframe: null })
    mockPermissions(['ticket.agent'])
    const { ticket } = defaultTicket()
    ticket.policy.update = true
    const article = createDeletableArticle(
      '123',
      false,
      false,
      new Date('1999 12 31'),
    )
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeDefined()
  })

  it.each(['ticket.customer', 'ticket.agent'])(
    "doesn't return article delete for non-editable tickets %s",
    (permission) => {
      mockPermissions([permission])
      const { ticket } = defaultTicket()
      ticket.policy.update = false
      const article = createDeletableArticle()
      const actions = createTestArticleActions(ticket, article)
      expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
    },
  )

  it("doesn't return article delete for customer", () => {
    mockPermissions(['ticket.customer'])
    const { ticket } = defaultTicket()
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)
    expect(actions.find((a) => a.name === 'articleDelete')).toBeUndefined()
  })
})
