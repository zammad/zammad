// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { beforeEach, expect } from 'vitest'

import createArticle from '#tests/graphql/factories/types/TicketArticle.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { type TicketArticleEdge } from '#shared/graphql/types.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })
  })

  describe('Article list', () => {
    it('shows see more button', async () => {
      mockTicketQuery({
        ticket: createDummyTicket(),
      })

      const firstArticleEdges: TicketArticleEdge[] = []
      const articlesEdges: TicketArticleEdge[] = []

      let count = 27

      while (count > 0) {
        const first = createArticle()

        const article = createArticle()

        if (count <= 5)
          firstArticleEdges.push(<TicketArticleEdge>{
            cursor: Buffer.from(count.toString()).toString('base64'),
            node: { ...first, internalId: count, sender: { name: 'Agent' } },
          })

        if (count > 5)
          articlesEdges.push(<TicketArticleEdge>{
            cursor: Buffer.from(count.toString()).toString('base64'),
            node: {
              ...article,
              internalId: 50 - count,
              sender: { name: 'Customer' },
            },
          })

        count--
      }

      mockTicketArticlesQuery({
        articles: {
          totalCount: 50,
          edges: articlesEdges,
          pageInfo: {
            hasPreviousPage: articlesEdges.length > 0,
            startCursor: articlesEdges.length > 0 ? articlesEdges[0].cursor : null,
            endCursor: btoa('50'),
          },
        },
        firstArticles: {
          edges: firstArticleEdges,
        },
      })

      const view = await visitView('/tickets/1')

      const feed = view.getByRole('feed')

      const articles = within(feed)
        .getAllByRole('article')
        .filter((article) => article.hasAttribute('aria-setsize'))

      expect(articles).toHaveLength(26) // 20 articles from end && 5 articles from the beginning 1 more button

      expect(
        within(articles.at(6) as HTMLElement).getByRole('button', {
          name: 'See more',
        }),
      ).toBeInTheDocument()
    })

    it('shows meta information if article is clicked', async () => {
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

      const view = await visitView('/tickets/1')

      const topHeader = within(view.getByTestId('ticket-detail-top-bar-full-details'))

      expect(
        await topHeader.findByRole('heading', { name: 'Test Ticket', level: 2 }),
      ).toBeInTheDocument()

      const ticketDetailHeader = view.getByTestId('ticket-detail-top-bar-full-details')

      expect(within(ticketDetailHeader).getByLabelText('Breadcrumb navigation')).toBeInTheDocument()

      expect(view.getByTestId('article-content')).toHaveTextContent('foobar')

      await view.events.click(view.getByTestId('article-bubble-body-1'))

      expect(await view.findByLabelText('Article meta information')).toBeInTheDocument()

      await view.events.click(view.getByTestId('article-bubble-body-1'))

      // NB: Click handler has a built-in timeout (200ms) to catch double click behavior.
      await waitFor(
        () => expect(view.queryByLabelText('Article meta information')).toHaveClass('hidden'), //. we test for the class as in js-dom toBeVisible won't work as expected
      )
    })
  })
})
