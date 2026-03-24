// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumBulkUpdateStatusStatus } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketUpdateBulkMutation,
  waitForTicketUpdateBulkMutationCalls,
} from '#desktop/entities/ticket/graphql/mutations/updateBulk.mocks.ts'
import { waitForTicketsCachedByOverviewQueryCalls } from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.mocks.ts'
import { waitForUserCurrentTicketOverviewsQueryCalls } from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.mocks.ts'
import { getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/ticketBulkUpdateStatusUpdates.mocks.ts'

import {
  mockDefaultOverviewQueries,
  mockDefaultTicketsCachedByOverview,
} from './mocks/ticket-overviews-mocks.ts'

describe('Ticket Overviews > Bulk edit tickets', () => {
  it('does not show bulk edit button when user is customer', async () => {
    mockDefaultOverviewQueries()

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
    expect(view.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()
  })

  it('selects a ticket for bulk edit', async () => {
    mockDefaultOverviewQueries()

    const ticket = createDummyTicket()

    mockDefaultTicketsCachedByOverview({
      edges: [{ node: ticket }],
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

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 10,
        failedCount: 0,
        inaccessibleTicketIds: [],
        invalidTicketIds: [],
      },
    })

    const view = await visitView('tickets/view/my_assigned')

    await waitForUserCurrentTicketOverviewsQueryCalls()

    expect(view.queryByRole('button', { name: 'Bulk action' })).not.toBeInTheDocument()

    await view.events.click(view.getByRole('checkbox', { name: 'Select this entry' }))

    await view.events.click(view.getByRole('button', { name: 'Bulk actions' }))

    expect(
      await view.findByRole('complementary', { name: 'Tickets bulk edit' }),
    ).toBeInTheDocument()

    const ticketState = await view.findByLabelText('State')

    await view.events.click(ticketState)

    expect(await view.findByRole('menu')).toBeInTheDocument()

    await view.events.click(view.getByRole('option', { name: 'closed' }))

    await view.events.click(view.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      perform: {
        input: {
          article: null,
          stateId: convertToGraphQLId('Ticket::State', 4),
        },
      },
      selector: {
        ticketIds: [ticket.id],
      },
    })

    expect(await waitForTicketsCachedByOverviewQueryCalls()).toHaveLength(2)
  })
})

describe('Ticket Overviews > Async bulk update notifications', () => {
  const setupBulkUpdateView = async () => {
    mockDefaultOverviewQueries()
    mockDefaultTicketsCachedByOverview({ edges: [{ node: createDummyTicket() }] })
    mockUserCurrent({
      permissions: { names: ['ticket.agent'] },
      preferences: { overviews_last_used: {} },
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          state_id: { options: [{ value: 4, label: 'closed' }] },
          pending_time: { show: false },
        },
      },
    })

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: true,
        total: 10,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })

    const view = await visitView('tickets/view/my_assigned')

    await waitForUserCurrentTicketOverviewsQueryCalls()

    await view.events.click(view.getByRole('checkbox', { name: 'Select this entry' }))
    await view.events.click(view.getByRole('button', { name: 'Bulk actions' }))

    const ticketState = await view.findByLabelText('State')
    await view.events.click(ticketState)
    await view.events.click(view.getByRole('option', { name: 'closed' }))
    await view.events.click(view.getByRole('button', { name: 'Apply' }))

    await waitForTicketUpdateBulkMutationCalls()

    return view
  }

  it('shows an info notification with a progress bar once an async bulk update is pending', async () => {
    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    const progressBar = view.getByRole('progressbar')
    expect(progressBar).toBeInTheDocument()
    expect(progressBar).toHaveAttribute('max', '10')
  })

  it('updates the progress bar as the subscription reports progress', async () => {
    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Running,
          total: 10,
          processedCount: 5,
          failedCount: 0,
        },
      },
    })

    await waitForNextTick()

    const progressBar = view.getByRole('progressbar')
    expect(progressBar).toHaveAttribute('value', '5')
    expect(progressBar).toHaveAttribute('max', '10')
  })

  it('keeps the notification visible when navigating away from the overview', async () => {
    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    const router = getTestRouter()
    await router.push('/dashboard')

    expect(view.getByText('Bulk action in progress…')).toBeInTheDocument()
    expect(view.getByRole('progressbar')).toBeInTheDocument()
  })

  it('hides the notification after the user dismisses it and does not show it again on subsequent updates', async () => {
    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    await view.events.click(view.getByRole('button', { name: 'Hide notification' }))

    // After dismissing, the notification should be gone, but the label replacing the button should still be there.
    expect(view.getAllByText('Bulk action in progress…')).toHaveLength(1)

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Running,
          total: 10,
          processedCount: 5,
          failedCount: 0,
        },
      },
    })

    await waitForNextTick()

    // Still there.
    expect(view.getAllByText('Bulk action in progress…')).toHaveLength(1)

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Succeeded,
          total: 10,
          processedCount: 10,
          failedCount: 0,
        },
      },
    })

    await waitForNextTick()

    // And... it's gone.
    expect(view.queryByText('Bulk action in progress…')).not.toBeInTheDocument()
  })

  it('shows the notification after logging out and back in while a bulk update is still running', async () => {
    mockUserCurrent({
      permissions: { names: ['ticket.agent'] },
      preferences: { overviews_last_used: {} },
    })
    mockDefaultOverviewQueries()
    mockDefaultTicketsCachedByOverview({ edges: [{ node: createDummyTicket() }] })

    const view = await visitView('tickets/view/my_assigned')

    expect(view.queryByText('Bulk action in progress…')).not.toBeInTheDocument()

    const router = getTestRouter()
    await router.push('/dashboard')

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Running,
          total: 10,
          processedCount: 5,
          failedCount: 0,
        },
      },
    })

    await waitForNextTick()

    await view.findByText('Bulk action in progress…')
  })

  it('shows the notification again if a new bulk update operation is started after the previous one completed', async () => {
    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: true,
        total: 10,
        failedCount: 0,
        invalidTicketIds: [],
        inaccessibleTicketIds: [],
      },
    })

    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Succeeded,
          total: 10,
          processedCount: 10,
          failedCount: 0,
        },
      },
    })

    await waitForNextTick()

    expect(view.queryByText('Bulk action in progress…')).not.toBeInTheDocument()

    // Start a new bulk update operation
    await view.events.click(view.getByRole('checkbox', { name: 'Select this entry' }))
    await view.events.click(view.getByRole('button', { name: 'Bulk actions' }))

    const ticketState = await view.findByLabelText('State')
    await view.events.click(ticketState)
    await view.events.click(view.getByRole('option', { name: 'closed' }))
    await view.events.click(view.getByRole('button', { name: 'Apply' }))

    await waitForTicketUpdateBulkMutationCalls()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)
  })

  it('replaces the progress notification with a success notification when the operation completes', async () => {
    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Succeeded,
          total: 10,
          processedCount: 10,
          failedCount: 0,
        },
      },
    })

    expect(await view.findByText('Bulk action successful for 10 ticket(s).')).toBeInTheDocument()
    expect(view.queryByText('Bulk action in progress…')).not.toBeInTheDocument()
    expect(view.queryByRole('progressbar')).not.toBeInTheDocument()
  })

  it('shows an additional error notification when some tickets fail during the bulk update', async () => {
    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Succeeded,
          total: 10,
          processedCount: 10,
          failedCount: 3,
        },
      },
    })

    expect(await view.findByText('Bulk action successful for 7 ticket(s).')).toBeInTheDocument()
    expect(view.queryByText('Bulk action in progress…')).not.toBeInTheDocument()
    expect(view.queryByRole('progressbar')).not.toBeInTheDocument()

    expect(
      view.getByText('Bulk action failed for 3 ticket(s). Check attribute values and try again.'),
    ).toBeInTheDocument()
  })

  it('shows only an error notification when all tickets fail during the bulk update', async () => {
    const view = await setupBulkUpdateView()

    // We expect two of the same labels: one in the notification message and one instead of the bulk actions button.
    expect(await view.findAllByText('Bulk action in progress…')).toHaveLength(2)

    await getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler().trigger({
      userCurrentTicketBulkUpdateStatusUpdates: {
        bulkUpdateStatus: {
          status: EnumBulkUpdateStatusStatus.Failed,
          total: 5,
          processedCount: 5,
          failedCount: 5,
        },
      },
    })

    expect(view.queryByText('Bulk action in progress…')).not.toBeInTheDocument()
    expect(view.queryByRole('progressbar')).not.toBeInTheDocument()

    expect(
      await view.findByText(
        'Bulk action failed for 5 ticket(s). Check attribute values and try again.',
      ),
    ).toBeInTheDocument()

    expect(view.queryByText(/Bulk action successful/)).not.toBeInTheDocument()
  })
})
