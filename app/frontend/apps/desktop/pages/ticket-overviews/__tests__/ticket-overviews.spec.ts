// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockCurrentUserQuery } from '#shared/graphql/queries/currentUser.mocks.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { getUserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/useCurrentOverviewOrderingFullAttributesUpdates.mocks.ts'
import { getUserCurrentTicketOverviewFullAttributesUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/userCurrentTicketOverviewFullAttributesUpdates.mocks.ts'

import {
  getDefaultOverviews,
  mockDefaultOverviewQueries,
  mockEmptyTicketsCachedByOverview,
} from './mocks/ticket-overviews-mocks.ts'

describe('TicketOverviews', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  it('redirects when overview does not exist', async () => {
    mockDefaultOverviewQueries()

    mockEmptyTicketsCachedByOverview()

    await visitView('tickets/view/does_not_exist')

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.path).toBe('/tickets/view/my_assigned'))
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
    ).toHaveAttribute('href', expect.stringContaining('/desktop/tickets/view'))

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    expect(secondaryNavigationSidebar).toHaveTextContent('My Assigned Tickets')

    expect(
      await view.findByRole('table', { name: 'Overview: My Assigned Tickets' }),
    ).toHaveTextContent('My Assigned TicketsState icon') //  deeper test is in TicketList
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

    mockDefaultOverviewQueries(overviews)

    const view = await visitView('tickets/view/my_assigned')

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    let currentOverviews = within(secondaryNavigationSidebar).getAllByRole('link')

    expect(currentOverviews[0]).toHaveTextContent('My Assigned Tickets')
    expect(currentOverviews[1]).toHaveTextContent('New Tickets')

    await getUserCurrentOverviewOrderingFullAttributesUpdatesSubscriptionHandler().trigger({
      userCurrentOverviewOrderingUpdates: generateObjectData(
        'UserCurrentOverviewOrderingUpdatesPayload',
        {
          overviews: overviews.reverse(),
        },
      ),
    })

    await waitForNextTick()

    currentOverviews = within(secondaryNavigationSidebar).getAllByRole('link')

    expect(currentOverviews[0]).toHaveTextContent('New Tickets')
    expect(currentOverviews[1]).toHaveTextContent('My Assigned Tickets')
  })

  it('updates overviews when subscription comes in', async () => {
    const overviews = getDefaultOverviews()

    mockDefaultOverviewQueries(overviews)

    const view = await visitView('tickets/view/my_assigned')

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    expect(within(secondaryNavigationSidebar).getAllByRole('link')).toHaveLength(2)

    await getUserCurrentTicketOverviewFullAttributesUpdatesSubscriptionHandler().trigger({
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
    })

    expect(within(secondaryNavigationSidebar).getAllByRole('link')).toHaveLength(3)
  })
})
