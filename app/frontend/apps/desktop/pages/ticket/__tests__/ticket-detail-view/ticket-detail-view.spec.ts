// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { beforeEach, expect } from 'vitest'

import createArticle from '#tests/graphql/factories/TicketArticle.ts'
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
        // eslint-disable-next-line no-plusplus
        count--
      }

      mockTicketArticlesQuery({
        articles: {
          totalCount: 50,
          edges: articlesEdges,
          pageInfo: {
            hasPreviousPage: articlesEdges.length > 0,
            startCursor:
              articlesEdges.length > 0 ? articlesEdges[0].cursor : null,
            endCursor: btoa('50'),
          },
        },
        firstArticles: {
          edges: firstArticleEdges,
        },
      })

      const view = await visitView('/tickets/1')

      const feed = view.getByRole('feed')

      const articles = within(feed).getAllByRole('article')

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

      expect(
        view.getByRole('heading', { name: 'Test Ticket', level: 2 }),
      ).toBeInTheDocument()

      const ticketDetailHeader = view.getByTestId(
        'visible-ticket-detail-top-bar',
      )

      expect(
        within(ticketDetailHeader).getByLabelText('Breadcrumb navigation'),
      ).toBeInTheDocument()

      expect(view.getByTestId('article-content')).toHaveTextContent('foobar')

      await view.events.click(view.getByTestId('article-bubble-body-1'))

      expect(
        await view.findByLabelText('Article meta information'),
      ).toBeInTheDocument()

      vi.useFakeTimers()

      await view.events.click(view.getByTestId('article-bubble-body-1'))

      // NB: Click handler has a built-in timeout (200ms) in order to catch double click behavior.
      //   Advance the timer manually so we speed up the test a bit.
      await vi.runAllTimersAsync()
      vi.useRealTimers()

      expect(
        view.queryByLabelText('Article meta information'),
      ).not.toBeInTheDocument()
    })
  })

  it('has invisible top bar and hides it from screen reader', async () => {
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

    expect(view.getByTestId('invisible-ticket-detail-top-bar')).toHaveAttribute(
      'aria-hidden',
      'true',
    )

    expect(view.getByTestId('invisible-ticket-detail-top-bar')).toHaveClass(
      'invisible',
    )
  })
})
