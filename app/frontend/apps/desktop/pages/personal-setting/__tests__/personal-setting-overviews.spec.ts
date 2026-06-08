// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getAllByRole } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { getUserCurrentOverviewOrderingUpdatesSubscriptionHandler } from '#desktop/entities/ticket/graphql/subscriptions/userCurrentOverviewOrderingUpdates.mocks.ts'

import { mockUserCurrentOverviewResetOrderMutation } from '../graphql/mutations/userCurrentOverviewResetOrder.mocks.ts'
import {
  mockUserCurrentOverviewListQuery,
  waitForUserCurrentOverviewListQueryCalls,
} from '../graphql/queries/userCurrentOverviewList.mocks.ts'

const userCurrentTicketOverviews = [
  {
    id: convertToGraphQLId('Overview', 1),
    name: 'Open Tickets',
    organizationShared: false,
    outOfOffice: false,
  },
  {
    id: convertToGraphQLId('Overview', 2),
    name: 'My Tickets',
    organizationShared: false,
    outOfOffice: false,
  },
  {
    id: convertToGraphQLId('Overview', 3),
    name: 'All Tickets',
    organizationShared: false,
    outOfOffice: false,
  },
]

const userCurrentOverviewListAfterReset = userCurrentTicketOverviews.reverse()

describe('personal settings for token access', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
      permissions: {
        names: ['user_preferences.overview_sorting', 'ticket.agent'],
      },
    })
  })

  it('shows the overviews order by priority', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentTicketOverviews })

    const view = await visitView('/personal-setting/ticket-overviews')

    const overviewContainer = view.getByLabelText('Order of ticket overviews')

    const overviews = getAllByRole(overviewContainer, 'listitem')

    userCurrentTicketOverviews.forEach((overview, index) => {
      expect(overviews[index]).toHaveTextContent(overview.name)
    })
  })

  // TODO: Cover the update of overview order when the items are moved around the list.
  //   We may need to implement a testable mechanism for reordering the list, though, as drag events are not fully
  //   supported in JSDOM due to missing client-rectangle coordinate mocking.
  //   One approach could be to add keyboard shortcuts for changing the order, or perhaps even hidden buttons.

  it('allows to reset the order of overviews', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentTicketOverviews })

    const view = await visitView('/personal-setting/ticket-overviews')

    mockUserCurrentOverviewResetOrderMutation({
      userCurrentOverviewResetOrder: {
        success: true,
        overviews: userCurrentOverviewListAfterReset,
        errors: null,
      },
    })

    const resetButton = view.getByRole('button', {
      name: 'Reset overview order',
    })

    expect(resetButton).toBeVisible()

    await view.events.click(resetButton)

    await waitForNextTick()

    expect(await view.findByRole('dialog', { name: 'Confirmation' })).toBeVisible()

    await view.events.click(view.getByRole('button', { name: 'Yes' }))

    await waitForNextTick()

    userCurrentOverviewListAfterReset.forEach((overview) => {
      expect(view.getByText(overview.name)).toBeVisible()
    })
  })

  it('updates the overviews list when a new overview is added', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentTicketOverviews })

    const view = await visitView('/personal-setting/ticket-overviews')

    const overviewUpdateSubscription = getUserCurrentOverviewOrderingUpdatesSubscriptionHandler()

    userCurrentTicketOverviews.forEach((overview) => {
      expect(view.getByText(overview.name)).toBeVisible()
    })

    overviewUpdateSubscription.trigger({
      userCurrentOverviewOrderingUpdates: {
        overviews: [
          ...userCurrentTicketOverviews,
          {
            id: convertToGraphQLId('Overview', 4),
            name: 'New Overview',
            organizationShared: false,
            outOfOffice: false,
          },
        ],
      },
    })

    await waitForNextTick()

    expect(view.getByText('New Overview')).toBeVisible()
  })

  it('shows a message when there are no overviews', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentTicketOverviews: [] })

    const view = await visitView('/personal-setting/ticket-overviews')

    await waitForUserCurrentOverviewListQueryCalls()

    expect(
      view.getByRole('heading', { name: 'exclamation-triangleNo overviews', level: 2 }),
    ).toBeVisible()

    expect(
      view.getByText(
        'Currently, no overviews are assigned to your roles. Please contact your administrator.',
      ),
    ).toBeVisible()
  })
})
