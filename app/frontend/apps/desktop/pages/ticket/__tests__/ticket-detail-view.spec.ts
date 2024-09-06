// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor, within } from '@testing-library/vue'

import createArticle from '#tests/graphql/factories/TicketArticle.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { waitForTicketUpdateMutationCalls } from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { getTicketUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumTicketArticleSenderName,
  type TicketArticleEdge,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { setupMocks } from '#desktop/pages/ticket/__tests__/support/ticket-edit-helpers.ts'
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
    await view.events.click(view.getByLabelText('Checklist'))

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
    await view.events.click(view.getByLabelText('Checklist'))

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
        id: convertToGraphQLId('Checklist', 1),
        name: 'Checklist title',
        items: [
          { text: 'Item 1', checked: true, ticketAccess: null, ticket: null },
          { text: 'Item 2', checked: false, ticketAccess: null, ticket: null },
        ],
        incomplete: 1,
      },
    })

    const view = await visitView('/tickets/1')
    await view.events.click(view.getByLabelText('Checklist'))

    expect(
      view.getByRole('status', { name: 'Incomplete checklist items' }),
    ).toHaveTextContent('1')

    const checklistCheckboxes = view.getAllByRole('checkbox')

    await getTicketChecklistUpdatesSubscriptionHandler().trigger({
      ticketChecklistUpdates: {
        ticketChecklist: {
          id: convertToGraphQLId('Checklist', 1),
          name: 'Checklist title',
          items: [
            { text: 'Item 1', checked: true },
            { text: 'Item 2', checked: true },
          ],
          incomplete: 0,
        },
      },
    })

    expect(
      view.queryByRole('status', { name: 'Incomplete checklist items' }),
    ).not.toBeInTheDocument()

    // Click manually in the frontend again on one of the checklist to show
    // the incomplete state again(without a subscription = manual cache update).
    await view.events.click(checklistCheckboxes[1])

    expect(
      await view.findByRole('status', { name: 'Incomplete checklist items' }),
    ).toBeInTheDocument()
  })

  describe('Ticket article actions', () => {
    describe.todo('email', () => {
      it.todo('replies to an article', async () => {
        mockPermissions(['ticket.agent'])

        await mockApplicationConfig({
          ui_ticket_zoom_article_note_new_internal: true,
        })

        mockTicketQuery({
          ticket: createDummyTicket({
            state: {
              id: convertToGraphQLId('Ticket::State', 1),
              name: 'open',
              stateType: {
                id: convertToGraphQLId('TicketStateType', 1),
                name: 'open',
              },
            },
            articleType: 'email',
            defaultPolicy: {
              update: true,
              agentReadAccess: true,
            },
          }),
        })

        const testArticle = createDummyArticle({
          articleType: 'email',
          internal: false,
          senderName: EnumTicketArticleSenderName.Customer,
        })

        mockTicketArticlesQuery({
          articles: {
            totalCount: 1,
            edges: [{ node: testArticle }],
          },
        })

        const view = await visitView('/tickets/1')

        await view.events.click(view.getByRole('button', { name: 'Add reply' }))
      })

      describe('dropdown actions', () => {
        it.todo('forwards an article', async () => {})
        it.todo('downloads raw email', async () => {})
      })
    })

    describe('dropdown shared actions', () => {
      it.todo('splits an article', async () => {})
      it.todo('copies article permalink', async () => {})
      it.todo('sets article to internal or public', async () => {})
    })

    describe('sidebar', () => {
      it.todo('updates ticket information to be closed', async () => {
        // :TODO test works in isolation but not if the whole test suite is running

        const ticket = createDummyTicket({
          state: {
            id: convertToGraphQLId('Ticket::State', 1),
            name: 'open',
            stateType: {
              id: convertToGraphQLId('TicketStateType', 1),
              name: 'open',
            },
          },
          articleType: 'email',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        })

        await setupMocks({ ticket })

        const view = await visitView('/tickets/1')

        expect(
          view.findByRole('heading', {
            level: 2,
            name: 'Ticket',
          }),
        )

        const statusBadges = view.getAllByTestId('common-badge')

        const hasOpenTicketStatus = statusBadges.some((badge) =>
          within(badge).getByText('open'),
        )

        expect(hasOpenTicketStatus).toBe(true)

        const ticketMetaSidebar = within(view.getByLabelText('Content sidebar'))

        await view.events.click(ticketMetaSidebar.getByLabelText('State'))

        expect(
          await view.findByRole('listbox', { name: 'Select…' }),
        ).toBeInTheDocument()

        expect(await view.findByRole('option', { name: 'closed' }))

        await view.events.click(view.getByRole('option', { name: 'closed' }))

        await view.events.click(view.getByRole('button', { name: 'Update' }))

        const calls = await waitForTicketUpdateMutationCalls()

        expect(calls?.at(-1)?.variables).toEqual({
          input: {
            article: null,
            groupId: convertToGraphQLId('Group', 2),
            objectAttributeValues: [],
            ownerId: convertToGraphQLId('User', 1),
            priorityId: convertToGraphQLId('Ticket::Priority', 3),
            stateId: convertToGraphQLId('Ticket::State', 2), // Updates from open to closed 1 -> 2
          },
          ticketId: convertToGraphQLId('Ticket', 1),
        })

        await getTicketUpdatesSubscriptionHandler().trigger({
          ticketUpdates: {
            ticket: {
              ...ticket,
              state: {
                ...ticket.state,
                id: convertToGraphQLId('Ticket::State', 2),
                name: 'closed',
              },
            },
          },
        })

        const hasClosedTicketStatus = statusBadges.some((badge) =>
          within(badge).getByText('closed'),
        )
        expect(hasClosedTicketStatus).toBe(true)
      })
    })

    it.todo('adds a phone call article', async () => {})

    it.todo('adds an internal note', async () => {
      mockPermissions(['ticket.agent'])

      await mockApplicationConfig({
        ui_ticket_zoom_article_note_new_internal: true,
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          ticketId: '1',
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
          edges: [
            {
              node: createDummyArticle({
                articleType: 'phone',
                internal: false,
              }),
            },
          ],
        },
      })

      const view = await visitView('/tickets/1')

      await view.events.click(
        view.getByRole('button', { name: 'Add internal note' }),
      )

      expect(
        await view.findByRole('heading', { level: 2, name: 'Reply' }),
      ).toBeInTheDocument()

      await getNode('form-ticket-edit')?.settled

      await view.events.type(
        view.getByRole('textbox', { name: 'Text' }),
        'Foo note',
      )

      await waitFor(() =>
        expect(view.getByRole('button', { name: 'Update' })).not.toBeDisabled(),
      )

      // Seems value gets set in the formkit tree
      // Textarea does not receive the value
      // Error state is not shown
      // const node = getNode('form-ticket-edit').at('article.body').context

      await view.events.click(view.getByRole('button', { name: 'Update' }))

      const calls = await waitForTicketUpdateMutationCalls()

      // :TODO continue here
      expect(calls?.at(-1)?.variables).toEqual({})
    })

    it.todo('discards unsaved changes', async () => {
      mockPermissions(['ticket.agent'])

      await mockApplicationConfig({
        ui_ticket_zoom_article_note_new_internal: true,
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          articleType: 'phone',
          defaultPolicy: {
            update: true,
            agentReadAccess: true,
          },
        }),
      })

      const view = await visitView('/tickets/1')

      await view.events.click(
        view.getByRole('button', { name: 'Add phone call' }),
      )

      expect(
        await view.findByRole('heading', { level: 2, name: 'Reply' }),
      ).toBeInTheDocument()

      await view.events.type(
        view.getByRole('textbox', { name: 'Text' }),
        'Foo note',
      )

      await view.events.click(
        view.getByRole('button', { name: 'Discard your unsaved changes' }),
      )

      const confirmDialog = await view.findByRole('dialog')

      expect(confirmDialog).toBeInTheDocument()

      await view.events.click(
        within(confirmDialog).getByRole('button', { name: 'Discard Changes' }),
      )

      expect(
        view.queryByRole('textbox', { name: 'Text' }),
      ).not.toBeInTheDocument()
    })
  })
})
