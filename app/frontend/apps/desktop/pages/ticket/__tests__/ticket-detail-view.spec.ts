// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { TicketArticle, TicketQuery } from '#shared/graphql/types.ts'

describe('ticket detail view', () => {
  describe('errors', () => {
    it.todo('redirects if ticket id is not found', async () => {
      await visitView('/tickets/232')
    })
  })

  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockTicketQuery({
      ticket: createDummyTicket() as TicketQuery['ticket'],
    })

    mockTicketArticlesQuery({
      articles: {
        edges: [{ node: createDummyArticle() as TicketArticle }],
      },
      firstArticles: {
        edges: [],
      },
    })
  })

  it('shows meta information if article is clicked', async () => {
    mockPermissions(['ticket.agent'])

    const view = await visitView('/tickets/1')

    expect(
      view.getByRole('heading', { name: 'Test Ticket' }),
    ).toBeInTheDocument()

    expect(view.getByLabelText('Breadcrumb navigation')).toBeInTheDocument()
  })
})
