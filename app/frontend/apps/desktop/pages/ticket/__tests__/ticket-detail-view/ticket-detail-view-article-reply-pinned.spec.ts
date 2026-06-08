// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

const setupView = () => {
  mockPermissions(['ticket.agent'])

  mockApplicationConfig({ ui_ticket_zoom_article_note_new_internal: true })

  mockLinkListQuery({ linkList: [] })

  mockTicketQuery({
    ticket: createDummyTicket({
      articleType: 'phone',
      defaultPolicy: {
        update: true,
        agentReadAccess: true,
      },
    }),
  })

  mockTicketArticlesQuery({
    articles: {
      totalCount: 1,
      edges: [{ node: createDummyArticle({ articleType: 'phone', internal: false }) }],
    },
  })

  mockFormUpdaterQuery({
    formUpdater: {
      fields: {
        group_id: { options: [{ value: 1, label: 'Users' }] },
        owner_id: { options: [{ value: 3, label: 'Test Admin Agent' }] },
        state_id: {
          options: [
            { value: 4, label: 'closed' },
            { value: 2, label: 'open' },
            { value: 6, label: 'pending close' },
            { value: 3, label: 'pending reminder' },
          ],
        },
        pending_time: { show: false },
        priority_id: {
          options: [
            { value: 1, label: '1 low' },
            { value: 2, label: '2 normal' },
            { value: 3, label: '3 high' },
          ],
        },
      },
      flags: { newArticlePresent: false },
    },
  })
}

describe('Ticket detail view - article reply pinned state', () => {
  afterEach(() => {
    localStorage.clear()
  })

  it('opens article reply form in pinned mode when localStorage value is set', async () => {
    setupView()
    mockUserCurrent()

    localStorage.setItem('article-reply-pinned', 'true')

    const view = await visitView('/tickets/1')

    await view.events.click(await view.findByRole('button', { name: 'Add internal note' }))

    const complementary = await view.findByRole('complementary', { name: 'Reply' })

    expect(complementary).toHaveAttribute('aria-expanded', 'false')
  })

  it('opens article reply form unpinned when no localStorage value is set', async () => {
    setupView()
    mockUserCurrent()

    const view = await visitView('/tickets/1')

    await view.events.click(await view.findByRole('button', { name: 'Add internal note' }))

    const complementary = await view.findByRole('complementary', { name: 'Reply' })

    expect(complementary).toHaveAttribute('aria-expanded', 'true')
  })
})
