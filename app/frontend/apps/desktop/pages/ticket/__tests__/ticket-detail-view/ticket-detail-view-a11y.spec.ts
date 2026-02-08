// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

// FIXME: All vitest-axe tests are currently skipped due to being incompatible with latest version of jsdom package.

describe('ticket detail view', () => {
  it.skip('has no accessibility violations in main content', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    mockLinkListQuery({
      linkList: [],
    })

    const testArticle = createDummyArticle()

    mockTicketArticlesQuery({
      articles: {
        totalCount: 1,
        edges: [{ node: testArticle }],
      },
      firstArticles: {
        edges: [{ node: testArticle }],
      },
    })

    const view = await visitView('/tickets/1')

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })
})
