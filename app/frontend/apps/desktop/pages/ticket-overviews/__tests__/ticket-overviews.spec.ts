// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { afterEach, beforeEach } from 'vitest'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { mockCurrentUserQuery } from '#shared/graphql/queries/currentUser.mocks.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForTicketUpdateBulkMutationCalls } from '#desktop/entities/ticket/graphql/mutations/updateBulk.mocks.ts'
import {
  mockTicketsCachedByOverviewQuery,
  waitForTicketsCachedByOverviewQueryCalls,
} from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.mocks.ts'
import {
  mockUserCurrentTicketOverviewsQuery,
  waitForUserCurrentTicketOverviewsQueryCalls,
} from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.mocks.ts'
import { getUserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/useCurrentOverviewOrderingFullAttributesUpdates.mocks.ts'
import { getUserCurrentTicketOverviewFullAttributesUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/userCurrentTicketOverviewFullAttributesUpdates.mocks.ts'

const mockDefaultOverviewQueries = () =>
  mockUserCurrentTicketOverviewsQuery({
    userCurrentTicketOverviews: [
      {
        id: convertToGraphQLId('Overview', 1),
        name: 'My Assigned Tickets',
        link: 'my_assigned',
        prio: 1000,
        orderBy: 'created_at',
        orderDirection: EnumOrderDirection.Ascending,
        active: true,
      },
    ],
  })

const getDefaultOverviews = () => [
  {
    id: convertToGraphQLId('Overview', 1),
    name: 'My Assigned Tickets',
    link: 'my_assigned',
    prio: 1000,
    orderBy: 'created_at',
    orderDirection: EnumOrderDirection.Ascending,
    viewColumns: [],
    orderColumns: [],
    active: true,
  },
  {
    id: convertToGraphQLId('Overview', 2),
    name: 'New Tickets',
    link: 'new_tickets',
    prio: 2000,
    orderBy: 'created_at',
    orderDirection: EnumOrderDirection.Ascending,
    viewColumns: [],
    orderColumns: [],
    active: true,
  },
]

describe('TicketOverviews', () => {
  it('redirects when overview does not exist', async () => {
    mockDefaultOverviewQueries()

    mockTicketsCachedByOverviewQuery({
      ticketsCachedByOverview: generateObjectData('TicketConnection', {
        totalCount: 0,
        edges: [],
        pageInfo: {
          endCursor: '',
          hasNextPage: false,
        },
      }),
    })

    await visitView('tickets/view/does_not_exist')

    const router = getTestRouter()

    await waitFor(() =>
      expect(router.currentRoute.value.path).toBe('/tickets/view/my_assigned'),
    )
  })

  it('displays overviews correctly', async () => {
    mockDefaultOverviewQueries()

    const view = await visitView('tickets/view/my_assigned')

    const primaryNavigationSidebar = view.getByRole('complementary', {
      name: 'Main sidebar',
    })

    expect(
      within(primaryNavigationSidebar).getByRole('link', {
        name: 'Overviews',
      }),
    ).toHaveAttribute('href', '/desktop/tickets/view')

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    expect(secondaryNavigationSidebar).toHaveTextContent('My Assigned Tickets')

    expect(
      await view.findByRole('table', { name: 'Overview: My Assigned Tickets' }),
    ).toHaveTextContent('My Assigned TicketsState Icon') //  deeper test is in TicketList
  })

  it('reorders overviews when subscription comes in', async () => {
    const overviews = getDefaultOverviews()

    mockCurrentUserQuery({
      currentUser: {
        preferences: {
          overviews_last_used: {
            '1': '2021-06-01T00:00:00.000Z',
            '2': '2021-06-01T00:00:00.000Z',
          },
        },
      },
    })

    mockUserCurrentTicketOverviewsQuery({
      userCurrentTicketOverviews: overviews,
    })

    const view = await visitView('tickets/view/my_assigned')

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    let currentOverviews = within(secondaryNavigationSidebar).getAllByRole(
      'link',
    )

    expect(currentOverviews[0]).toHaveTextContent('My Assigned Tickets')
    expect(currentOverviews[1]).toHaveTextContent('New Tickets')

    await getUserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionHandler().trigger(
      {
        userCurrentOverviewOrderingUpdates: generateObjectData(
          'UserCurrentOverviewOrderingUpdatesPayload',
          {
            overviews: overviews.reverse(),
          },
        ),
      },
    )

    await waitForNextTick()

    currentOverviews = within(secondaryNavigationSidebar).getAllByRole('link')

    expect(currentOverviews[0]).toHaveTextContent('New Tickets')
    expect(currentOverviews[1]).toHaveTextContent('My Assigned Tickets')
  })

  it('updates overviews when subscription comes in', async () => {
    // ticketsCachedCountByOverview will be removed soon
    const overviews = getDefaultOverviews()

    mockUserCurrentTicketOverviewsQuery({
      userCurrentTicketOverviews: overviews,
    })

    const view = await visitView('tickets/view/my_assigned')

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    expect(
      within(secondaryNavigationSidebar).getAllByRole('link'),
    ).toHaveLength(2)

    await getUserCurrentTicketOverviewFullAttributesUpdatesSubscriptionHandler().trigger(
      {
        userCurrentTicketOverviewUpdates: generateObjectData(
          'UserCurrentTicketOverviewUpdatesPayload',
          {
            ticketOverviews: [
              ...overviews,
              {
                id: convertToGraphQLId('Overview', 3),
                name: 'Foo Tickets',
                link: 'foo_tickets',
                prio: 2000,
                orderBy: 'created_at',
                orderDirection: EnumOrderDirection.Ascending,
                active: true,
              },
            ],
          },
        ),
      },
    )

    expect(
      within(secondaryNavigationSidebar).getAllByRole('link'),
    ).toHaveLength(3)
  })

  describe('empty states', () => {
    it('displays a message to the agent when no overviews are available.', async () => {
      mockUserCurrentTicketOverviewsQuery({
        userCurrentTicketOverviews: [],
      })

      const view = await visitView('tickets/view')

      expect(
        await view.findByText(
          'Currently, no overviews are assigned to your roles. Please contact your administrator.',
        ),
      ).toBeInTheDocument()

      expect(view.getByRole('heading', { level: 2 })).toHaveTextContent(
        'No Overviews',
      )

      expect(view.getByIconName('exclamation-triangle')).toBeInTheDocument()

      expect(
        view.queryByLabelText('second level navigation sidebar'),
      ).not.toBeInTheDocument()
    })
  })

  it('displays a ticket create message to the customer when no tickets are available and no ticket history', async () => {
    mockUserCurrentTicketOverviewsQuery({
      userCurrentTicketOverviews: [
        generateObjectData('Overview', {
          id: convertToGraphQLId('Overview', 1),
          name: 'My Tickets',
          link: 'my_tickets',
          prio: 9,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Ascending,
          organizationShared: false,
          outOfOffice: false,
          active: true,
        }),
      ],
    })

    mockCurrentUserQuery({
      currentUser: {
        preferences: {
          tickets_closed: 0,
          tickets_open: 0,
          overviews_last_used: {},
        },
      },
    })

    mockTicketsCachedByOverviewQuery({
      ticketsCachedByOverview: generateObjectData('TicketConnection', {
        totalCount: 0,
        edges: [],
        pageInfo: {
          endCursor: '',
          hasNextPage: false,
        },
      }),
    })

    mockPermissions(['ticket.customer'])

    mockApplicationConfig({ customer_ticket_create: true })

    const view = await visitView('tickets/view')

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    expect(
      within(secondaryNavigationSidebar).getByRole('link', {
        name: 'My Tickets 0', // 0 comes from the ticket count
      }),
    ).toBeInTheDocument()

    expect(await view.findByRole('heading', { level: 2 })).toHaveTextContent(
      'Welcome!',
    )

    expect(
      view.getByText('You have not created a ticket yet.'),
    ).toBeInTheDocument()
    expect(
      view.getByText(
        'The way to communicate with us is this thing called "ticket".',
      ),
    ).toBeInTheDocument()
    expect(
      view.getByText(
        'Please click on the button below to create your first one.',
      ),
    ).toBeInTheDocument()

    await view.events.click(
      view.getByRole('button', { name: 'Create your first ticket' }),
    )

    const router = getTestRouter()

    await waitFor(() =>
      expect(router.currentRoute.value.name).toBe('TicketCreate'),
    )
  })

  it('displays a message indicating no tickets are available when the overview is empty', async () => {
    mockUserCurrentTicketOverviewsQuery({
      userCurrentTicketOverviews: [
        generateObjectData('Overview', {
          id: convertToGraphQLId('Overview', 1),
          name: 'My Assigned Tickets',
          link: 'my_assigned',
          prio: 4,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Ascending,
          organizationShared: false,
          outOfOffice: false,
          active: true,
        }),
      ],
    })

    mockCurrentUserQuery({
      currentUser: {
        preferences: {
          tickets_closed: 1,
          tickets_open: 2,
        },
      },
    })

    mockTicketsCachedByOverviewQuery({
      ticketsCachedByOverview: generateObjectData('TicketConnection', {
        totalCount: 0,
        edges: [],
        pageInfo: {
          endCursor: '',
          hasNextPage: false,
        },
      }),
    })

    mockPermissions(['ticket.agent'])

    const view = await visitView('tickets/view')

    expect(await view.findByRole('heading', { level: 2 })).toHaveTextContent(
      'Empty Overview',
    )

    expect(view.getByText('No tickets in this state.')).toBeInTheDocument()
  })

  describe('polling overviews', () => {
    beforeEach(vi.useFakeTimers)
    afterEach(vi.useRealTimers)

    it.todo('polls for the active overviews', async () => {
      mockDefaultOverviewQueries()

      mockUserCurrent({
        preferences: {
          overviews_last_used: {},
        },
      })

      await visitView('tickets/view/my_assigned')

      const mocks = await waitForUserCurrentTicketOverviewsQueryCalls()

      expect(mocks).toHaveLength(1)

      const config = {
        foreground: {
          interval_sec: 5,
          cache_ttl_sec: 5,
        },
      }
      setQueryPollingConfig(config)

      await vi.advanceTimersByTimeAsync(config.foreground.interval_sec * 1000)
      await vi.advanceTimersToNextTimerAsync()

      expect(mocks).toHaveLength(2)
      // await waitFor(() => expect(mocks).toHaveLength(2))
    })

    it.todo('polls for the background overviews', async () => {
      mockDefaultOverviewQueries()

      mockCurrentUserQuery({
        currentUser: {
          preferences: {
            overviews_last_used: {
              '2': '2021-06-01T00:00:00.000Z',
            },
          },
        },
      })

      await visitView('tickets/view/my_assigned')

      // const mocks = await waitForUserCurrentTicketOverviewsQueryCalls()
    })

    it('disables polling when the config is disabled', async () => {
      mockDefaultOverviewQueries()

      await visitView('tickets/view/my_assigned')

      setQueryPollingConfig({
        disabled: true,
      })

      const mocks = await waitForUserCurrentTicketOverviewsQueryCalls()

      expect(mocks).toHaveLength(1)

      // :TODO fix this
      await vi.advanceTimersByTimeAsync(5 * 1000)
      await vi.advanceTimersToNextTimerAsync()

      expect(mocks).toHaveLength(1)
    })
  })

  describe('bulk edit tickets', () => {
    it('does not show bulk edit button when user is customer', async () => {
      mockUserCurrentTicketOverviewsQuery({
        userCurrentTicketOverviews: getDefaultOverviews(),
      })

      mockPermissions(['ticket.customer'])

      mockUserCurrent({
        preferences: {
          overviews_last_used: {
            '1': '2021-06-01T00:00:00.000Z',
            '2': '2021-06-01T00:00:00.000Z',
          },
        },
      })

      const view = await visitView('tickets/view/my_assigned')

      expect(view.queryByRole('checkbox')).not.toBeInTheDocument()
      expect(
        view.queryByRole('button', { name: 'Bulk Actions' }),
      ).not.toBeInTheDocument()
    })

    it('selects a ticket for bulk edit', async () => {
      mockUserCurrentTicketOverviewsQuery({
        userCurrentTicketOverviews: [
          generateObjectData('Overview', {
            id: convertToGraphQLId('Overview', 1),
            name: 'My Assigned Tickets',
            link: 'my_assigned',
            prio: 4,
            orderBy: 'created_at',
            orderDirection: EnumOrderDirection.Ascending,
            organizationShared: false,
            outOfOffice: false,
            active: true,
          }),
        ],
      })

      const ticket = createDummyTicket()

      mockTicketsCachedByOverviewQuery({
        ticketsCachedByOverview: generateObjectData('TicketConnection', {
          totalCount: 1,
          edges: [
            {
              cursor: 'MQ',
              node: ticket,
            },
          ],
          pageInfo: {
            endCursor: '',
            hasNextPage: false,
          },
        }),
      })

      mockUserCurrent({
        permissions: {
          names: ['ticket.agent'],
        },
        preferences: {
          overviews_last_used: {},
        },
      })

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            group_id: {
              options: [
                {
                  value: 2,
                  label: 'test group',
                },
              ],
            },
            owner_id: {
              options: [
                {
                  value: 3,
                  label: 'Test Admin Agent',
                },
              ],
            },
            state_id: {
              options: [
                {
                  value: 4,
                  label: 'closed',
                },
              ],
            },
            pending_time: {
              show: false,
            },
          },
        },
      })

      const view = await visitView('tickets/view/my_assigned')

      await waitForUserCurrentTicketOverviewsQueryCalls()

      expect(
        view.queryByRole('button', { name: 'Bulk Action' }),
      ).not.toBeInTheDocument()

      await view.events.click(
        view.getByRole('checkbox', { name: 'Select this entry' }),
      )

      await view.events.click(
        view.getByRole('button', { name: 'Bulk Actions' }),
      )

      expect(
        await view.findByRole('complementary', { name: 'Tickets Bulk Edit' }),
      ).toBeInTheDocument()

      const ticketState = await view.findByLabelText('State')

      await view.events.click(ticketState)

      expect(await view.findByRole('menu')).toBeInTheDocument()

      await view.events.click(view.getByRole('option', { name: 'closed' }))

      await view.events.click(view.getByRole('button', { name: 'Apply' }))

      const calls = await waitForTicketUpdateBulkMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          article: null,
          stateId: convertToGraphQLId('Ticket::State', 4),
        },
        ticketIds: [ticket.id],
      })

      expect(await waitForTicketsCachedByOverviewQueryCalls()).toHaveLength(2)
    })
  })
})
