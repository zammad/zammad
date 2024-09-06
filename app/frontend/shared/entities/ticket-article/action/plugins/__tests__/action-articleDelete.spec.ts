// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { setupView } from '#tests/support/mock-user.ts'

import type { TicketView } from '#shared/entities/ticket/types.ts'

import {
  createTicketArticle,
  createTestArticleActions,
  createTicket,
} from './utils.ts'

const createDeletableArticle = (
  userId = '123',
  isCommunication = false,
  isInternal = true,
  createdAt: Date = new Date(),
) => {
  const article = createTicketArticle()
  article.author!.id = userId
  article.type!.communication = isCommunication
  article.internal = isInternal
  article.createdAt = createdAt.toISOString()
  return article
}

describe('article delete action', () => {
  it('returns article delete for editable ticket', () => {
    setupView('agent')
    const ticket = createTicket({ policy: { update: true } })
    const article = createDeletableArticle()
    const actions = createTestArticleActions(ticket, article)

    expect(actions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ name: 'articleDelete' }),
      ]),
    )
  })
  it('does not return article delete for article created by another user', () => {
    setupView('agent')
    const ticket = createTicket({ policy: { update: true } })
    const article = createDeletableArticle('456')
    const actions = createTestArticleActions(ticket, article)

    expect(actions).toEqual(
      expect.not.arrayContaining([
        expect.objectContaining({ name: 'articleDelete' }),
      ]),
    )
  })

  it('does not return article delete for communication article', () => {
    setupView('agent')
    const ticket = createTicket({ policy: { update: true } })
    const article = createDeletableArticle('123', true, false)
    const actions = createTestArticleActions(ticket, article)

    expect(actions).toEqual(
      expect.not.arrayContaining([
        expect.objectContaining({ name: 'articleDelete' }),
      ]),
    )
  })

  it('returns article delete for internal communication article', () => {
    setupView('agent')
    const ticket = createTicket({ policy: { update: true } })
    const article = createDeletableArticle('123', true, true)
    const actions = createTestArticleActions(ticket, article)

    expect(actions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ name: 'articleDelete' }),
      ]),
    )
  })

  it('does not return article delete for old article', () => {
    mockApplicationConfig({ ui_ticket_zoom_article_delete_timeframe: 600 })
    setupView('agent')
    const ticket = createTicket({ policy: { update: true } })
    const article = createDeletableArticle(
      '123',
      false,
      false,
      new Date('1999 12 31'),
    )
    const actions = createTestArticleActions(ticket, article)

    expect(actions).toEqual(
      expect.not.arrayContaining([
        expect.objectContaining({ name: 'articleDelete' }),
      ]),
    )
  })

  it('returns article delete for old article if delete timeframe is disabled', () => {
    mockApplicationConfig({
      ui_ticket_zoom_article_delete_timeframe: undefined,
    })
    setupView('agent')
    const ticket = createTicket({ policy: { update: true } })
    const article = createDeletableArticle(
      '123',
      false,
      false,
      new Date('1999 12 31'),
    )
    const actions = createTestArticleActions(ticket, article)
    expect(actions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ name: 'articleDelete' }),
      ]),
    )
  })

  const views: TicketView[] = ['agent', 'customer']
  it.each(views)(
    "doesn't return article delete for non-editable tickets %s",
    (view) => {
      setupView(view)
      const ticket = createTicket({ policy: { update: false } })
      const article = createDeletableArticle()
      const actions = createTestArticleActions(ticket, article)

      expect(actions).toEqual(
        expect.not.arrayContaining([
          expect.objectContaining({ name: 'articleDelete' }),
        ]),
      )
    },
  )

  it("doesn't return article delete for customer", () => {
    setupView('customer')
    const ticket = createTicket({ policy: { update: true } })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article)

    expect(actions).toEqual(
      expect.not.arrayContaining([
        expect.objectContaining({ name: 'articleDelete' }),
      ]),
    )
  })
})
