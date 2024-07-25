// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { describe } from 'vitest'
import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { TicketArticle, TicketQuery } from '#shared/graphql/types.ts'

describe.skip('ticket detail view', () => {
  it('has no accessibility violations in main content', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketQuery({
      ticket: createDummyTicket() as TicketQuery['ticket'],
    })

    mockTicketArticlesQuery({
      articles: {
        totalCount: 1,
        edges: [{ node: createDummyArticle() as TicketArticle }],
      },
      firstArticles: {
        edges: [],
      },
    })

    const view = await visitView('/tickets/1')

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })
})
