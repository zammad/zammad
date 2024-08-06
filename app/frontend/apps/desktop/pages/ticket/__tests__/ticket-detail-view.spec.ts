// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

describe('ticket detail view', () => {
  describe('errors', () => {
    it.todo('redirects if ticket id is not found', async () => {
      await visitView('/tickets/232')
    })
  })

  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    const testArticle = createDummyArticle({
      bodyWithUrls: 'foobar',
    })

    mockTicketArticlesQuery({
      articles: {
        totalCount: 1,
        edges: [{ node: testArticle }],
      },
      firstArticles: {
        edges: [{ node: testArticle }],
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

    // TODO: Non sequitur
    expect(view.getByTestId('article-content')).toHaveTextContent('foobar')
  })
})
