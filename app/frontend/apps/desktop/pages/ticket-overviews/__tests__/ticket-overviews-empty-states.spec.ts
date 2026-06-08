// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockCurrentUserQuery } from '#shared/graphql/queries/currentUser.mocks.ts'

import {
  mockDefaultOverviewQueries,
  mockEmptyTicketsCachedByOverview,
} from './mocks/ticket-overviews-mocks.ts'

describe('Ticket Overviews > Empty states', () => {
  it('displays a message to the agent when no overviews are available.', async () => {
    mockDefaultOverviewQueries([])

    const view = await visitView('tickets/view')

    expect(
      await view.findByText(
        'Currently, no overviews are assigned to your roles. Please contact your administrator.',
      ),
    ).toBeInTheDocument()

    expect(view.getByRole('heading', { level: 2 })).toHaveTextContent('No overviews')

    expect(view.getByIconName('exclamation-triangle')).toBeInTheDocument()

    expect(view.queryByLabelText('second level navigation sidebar')).not.toBeInTheDocument()
  })

  it('displays a ticket create message to the customer when no tickets are available and no ticket history', async () => {
    mockDefaultOverviewQueries()

    mockCurrentUserQuery({
      currentUser: {
        preferences: {
          tickets_closed: 0,
          tickets_open: 0,
          overviews_last_used: {},
        },
      },
    })

    mockEmptyTicketsCachedByOverview()

    mockPermissions(['ticket.customer'])

    mockApplicationConfig({ customer_ticket_create: true })

    const view = await visitView('tickets/view')

    const secondaryNavigationSidebar = await view.findByRole('complementary', {
      name: 'second level navigation sidebar',
    })

    expect(
      within(secondaryNavigationSidebar).getByRole('link', {
        name: 'My Assigned Tickets0', // 0 comes from the ticket count
      }),
    ).toBeInTheDocument()

    expect(await view.findByRole('heading', { level: 2 })).toHaveTextContent('Welcome!')

    expect(view.getByText('You have not created a ticket yet.')).toBeInTheDocument()
    expect(
      view.getByText('The way to communicate with us is this thing called "ticket".'),
    ).toBeInTheDocument()
    expect(
      view.getByText('Please click on the button below to create your first one.'),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Create your first ticket' }))

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('TicketCreate'))
  })

  it('displays a message indicating no tickets are available when the overview is empty', async () => {
    mockDefaultOverviewQueries()

    mockCurrentUserQuery({
      currentUser: {
        preferences: {
          tickets_closed: 1,
          tickets_open: 2,
        },
      },
    })

    mockEmptyTicketsCachedByOverview()

    mockPermissions(['ticket.agent'])

    const view = await visitView('tickets/view')

    expect(await view.findByRole('heading', { level: 2 })).toHaveTextContent('Empty overview')

    expect(view.getByText('No tickets in this state.')).toBeInTheDocument()
  })
})
