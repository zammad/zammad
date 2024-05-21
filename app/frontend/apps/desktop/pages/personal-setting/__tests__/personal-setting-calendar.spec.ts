// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { getCurrentUserUpdatesSubscriptionHandler } from '#shared/graphql/subscriptions/currentUserUpdates.mocks.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import {
  mockUserCurrentCalendarSubscriptionUpdate,
  waitForUserCurrentCalendarSubscriptionUpdateCalls,
} from '../graphql/mutations/userCurrentCalendarSubscriptionUpdate.mocks.ts'
import { mockUserCurrentCalendarSubscriptionList } from '../graphql/queries/userCurrentCalendarSubscriptionList.mocks.ts'

describe('personal calendar subscription settings', () => {
  beforeEach(() => {
    mockPermissions(['user_preferences.calendar+ticket.agent'])

    mockUserCurrentCalendarSubscriptionList({
      userCurrentCalendarSubscriptionList: {
        combinedUrl: 'https://zammad.example.com/ical/tickets',
        globalOptions: {
          alarm: false,
        },
        escalation: {
          url: 'https://zammad.example.com/ical/tickets/escalation',
          options: {
            own: true,
            notAssigned: false,
          },
        },
        newOpen: {
          url: 'https://zammad.example.com/ical/tickets/new_open',
          options: {
            own: false,
            notAssigned: true,
          },
        },
        pending: {
          url: 'https://zammad.example.com/ical/tickets/pending',
          options: {
            own: true,
            notAssigned: true,
          },
        },
      },
    })
  })

  it('renders view correctly', async () => {
    const view = await visitView('personal-setting/calendar-subscriptions')

    expect(view.getByLabelText('Combined subscription URL')).toHaveValue(
      'https://zammad.example.com/ical/tickets',
    )

    expect(
      view.getByLabelText(
        'Add alarm to pending reminder and escalated tickets',
      ),
    ).toBeInTheDocument()

    expect(
      view.getByRole('tab', { name: 'Escalated Tickets' }),
    ).toBeInTheDocument()

    expect(
      view.getByRole('tab', { name: 'New & Open Tickets' }),
    ).toBeInTheDocument()

    expect(
      view.getByRole('tab', { name: 'Pending Tickets' }),
    ).toBeInTheDocument()
  })

  it('switches tab panels correctly', async () => {
    const view = await visitView('personal-setting/calendar-subscriptions')

    const escalationTab = view.getByRole('tab', { name: 'Escalated Tickets' })

    expect(escalationTab).toHaveAttribute('aria-selected', 'true')

    expect(view.getByLabelText('Direct subscription URL')).toHaveValue(
      'https://zammad.example.com/ical/tickets/escalation',
    )

    expect(view.getAllByLabelText('My tickets')[0]).toBeChecked()
    expect(view.getAllByLabelText('Not assigned')[0]).not.toBeChecked()

    const newOpenTab = view.getByRole('tab', { name: 'New & Open Tickets' })

    await view.events.click(newOpenTab)

    expect(escalationTab).toHaveAttribute('aria-selected', 'false')
    expect(newOpenTab).toHaveAttribute('aria-selected', 'true')

    expect(view.getByLabelText('Direct subscription URL')).toHaveValue(
      'https://zammad.example.com/ical/tickets/new_open',
    )

    expect(view.getAllByLabelText('My tickets')[1]).not.toBeChecked()
    expect(view.getAllByLabelText('Not assigned')[1]).toBeChecked()

    const pendingTab = view.getByRole('tab', { name: 'Pending Tickets' })

    await view.events.click(pendingTab)

    expect(newOpenTab).toHaveAttribute('aria-selected', 'false')
    expect(pendingTab).toHaveAttribute('aria-selected', 'true')

    expect(view.getByLabelText('Direct subscription URL')).toHaveValue(
      'https://zammad.example.com/ical/tickets/pending',
    )

    expect(view.getAllByLabelText('My tickets')[2]).toBeChecked()
    expect(view.getAllByLabelText('Not assigned')[2]).toBeChecked()
  })

  it('updates calendar subscription when alarm is toggled', async () => {
    const view = await visitView('personal-setting/calendar-subscriptions')

    mockUserCurrentCalendarSubscriptionUpdate({
      userCurrentCalendarSubscriptionUpdate: {
        success: true,
        errors: null,
      },
    })

    await view.events.click(
      view.getByLabelText(
        'Add alarm to pending reminder and escalated tickets',
      ),
    )

    const calls = await waitForUserCurrentCalendarSubscriptionUpdateCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        alarm: true,
      }),
    })
  })

  it('updates calendar subscription when form is changed', async () => {
    const view = await visitView('personal-setting/calendar-subscriptions')

    mockUserCurrentCalendarSubscriptionUpdate({
      userCurrentCalendarSubscriptionUpdate: {
        success: true,
        errors: null,
      },
    })

    await view.events.click(view.getAllByLabelText('My tickets')[0])

    const calls = await waitForUserCurrentCalendarSubscriptionUpdateCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        escalation: expect.objectContaining({
          own: false,
        }),
      }),
    })
  })

  it('updates calendar subscription when different tab is changed', async () => {
    const view = await visitView('personal-setting/calendar-subscriptions')

    await view.events.click(
      view.getByRole('tab', { name: 'New & Open Tickets' }),
    )

    mockUserCurrentCalendarSubscriptionUpdate({
      userCurrentCalendarSubscriptionUpdate: {
        success: true,
        errors: null,
      },
    })

    await view.events.click(view.getAllByLabelText('My tickets')[1])

    const calls = await waitForUserCurrentCalendarSubscriptionUpdateCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: expect.objectContaining({
        escalation: expect.objectContaining({
          own: true,
        }),
      }),
    })
  })

  it('resets state when session store is updated', async () => {
    const view = await visitView('personal-setting/calendar-subscriptions')

    // Mock opposite states than what was loaded with the initial request.
    mockUserCurrentCalendarSubscriptionList({
      userCurrentCalendarSubscriptionList: {
        combinedUrl: 'https://zammad.example.com/ical/tickets',
        globalOptions: {
          alarm: true,
        },
        escalation: {
          url: 'https://zammad.example.com/ical/tickets/escalation',
          options: {
            own: false,
            notAssigned: true,
          },
        },
        newOpen: {
          url: 'https://zammad.example.com/ical/tickets/new_open',
          options: {
            own: true,
            notAssigned: false,
          },
        },
        pending: {
          url: 'https://zammad.example.com/ical/tickets/pending',
          options: {
            own: false,
            notAssigned: false,
          },
        },
      },
    })

    // Trigger the current user query, so the user updates subscription is put in place.
    //   Normally, this is not needed in the test environment, but here we depend on the mechanism, so we can trigger
    //   the subscription located in the session store and in turn form updates.
    const { getCurrentUser } = useSessionStore()

    const user = await getCurrentUser()

    // Just trigger the subscription with the same data, new state will come from its own query anyway.
    await getCurrentUserUpdatesSubscriptionHandler().trigger({
      userUpdates: {
        user,
      },
    })

    expect(
      view.getByLabelText(
        'Add alarm to pending reminder and escalated tickets',
      ),
    ).toBeChecked()

    expect(view.getAllByLabelText('My tickets')[0]).not.toBeChecked()
    expect(view.getAllByLabelText('Not assigned')[0]).toBeChecked()
    expect(view.getAllByLabelText('My tickets')[1]).toBeChecked()
    expect(view.getAllByLabelText('Not assigned')[1]).not.toBeChecked()
    expect(view.getAllByLabelText('My tickets')[2]).not.toBeChecked()
    expect(view.getAllByLabelText('Not assigned')[2]).not.toBeChecked()
  })
})
