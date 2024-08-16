// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import createArticle from '#tests/graphql/factories/TicketArticle.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { TicketArticleEdge } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.mocks.ts'
import { getTicketChecklistUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketChecklistUpdates.mocks.ts'

describe('ticket detail view', () => {
  describe('errors', () => {
    it.todo('redirects if ticket id is not found', async () => {
      mockPermissions(['ticket.agent'])

      // :TODO test test as soon as the bug for the Query has complexity of 19726, has been resolved
      mockTicketQuery({
        ticket: null,
      })

      await visitView('/tickets/232')

      const router = getTestRouter()

      expect(router.currentRoute.value.name).toEqual('Error')
    })
  })

  it('shows see more button', async () => {
    mockPermissions(['ticket.agent'])

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
      view.getByRole('heading', { name: 'Test Ticket', level: 2 }),
    ).toBeInTheDocument()

    expect(view.getByLabelText('Breadcrumb navigation')).toBeInTheDocument()

    expect(view.getByTestId('article-content')).toHaveTextContent('foobar')

    await view.events.click(view.getByTestId('article-bubble-body-1'))

    expect(
      await view.findByLabelText('Article meta information'),
    ).toBeInTheDocument()

    await view.events.click(view.getByTestId('article-bubble-body-1'))

    expect(
      view.queryByLabelText('Article meta information'),
    ).not.toBeInTheDocument()
  })

  it('shows checklist if it is enabled and user is agent', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({ checklist: true })

    const view = await visitView('/tickets/1')

    expect(
      view.getByRole('heading', { name: 'Checklist', level: 2 }),
    ).toBeInTheDocument()
  })

  it('hides checklist if it is disabled and user is agent', async () => {
    mockPermissions(['ticket.agent'])
    await mockApplicationConfig({ checklist: false })

    const view = await visitView('/tickets/1')

    expect(
      view.queryByRole('heading', { name: 'Checklist', level: 2 }),
    ).not.toBeInTheDocument()
  })

  it('hides checklist if it is enabled and user is customer', async () => {
    mockPermissions(['ticket.customer'])
    await mockApplicationConfig({ checklist: true })

    const view = await visitView('/tickets/1')

    expect(
      view.queryByRole('heading', { name: 'Checklist', level: 2 }),
    ).not.toBeInTheDocument()
  })

  it('shows checklist ticket link for readonly agent', async () => {
    await mockApplicationConfig({ checklist: true })
    mockPermissions(['ticket.agent'])

    mockTicketChecklistQuery({
      ticketChecklist: {
        id: convertToGraphQLId('Checklist', 1),
        name: 'Checklist title',
        items: [
          {
            __typename: 'ChecklistItem',
            id: convertToGraphQLId('Checklist::Item', 2),
            text: 'Checklist item B',
            ticketAccess: null,
            checked: false,
            ticket: createDummyTicket(),
          },
        ],
      },
    })

    const view = await visitView('/tickets/1')

    const checklist = view.getByRole('heading', { name: 'Checklist', level: 2 })
    expect(checklist).toBeInTheDocument()

    // Checking display  of ticket link
    expect(view.getByRole('link', { name: 'Test Ticket' })).toBeInTheDocument()

    // Ticket link has single item menu, hence we have to test it does not exist in readonly
    expect(
      within(checklist).queryByRole('button', { name: 'Remove item' }),
    ).not.toBeInTheDocument()
  })

  it('updates incomplete checklist item count', async () => {
    mockPermissions(['ticket.agent'])

    await mockApplicationConfig({ checklist: true })

    mockTicketChecklistQuery({
      ticketChecklist: {
        name: 'Checklist title',
        items: [
          { text: 'Item 1', checked: true, ticketAccess: null, ticket: null },
          { text: 'Item 2', checked: false, ticketAccess: null, ticket: null },
        ],
        incomplete: 1,
      },
    })

    const view = await visitView('/tickets/1')

    expect(
      view.getByRole('status', { name: 'Incomplete checklist items' }),
    ).toHaveTextContent('1')

    const checklistCheckboxes = view.getAllByRole('checkbox')

    await getTicketChecklistUpdatesSubscriptionHandler().trigger({
      ticketChecklistUpdates: {
        ticketChecklist: {
          name: 'Checklist title',
          items: [
            { text: 'Item 1', checked: true },
            { text: 'Item 2', checked: true },
          ],
          incomplete: 0,
        },
      },
    })

    await view.events.click(checklistCheckboxes[0])

    expect(
      view.queryByRole('status', { name: 'Incomplete checklist items' }),
    ).not.toBeInTheDocument()
  })
})
