// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getAllByRole } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentOverviewResetOrderMutation } from '../graphql/mutations/userCurrentOverviewResetOrder.mocks.ts'
import { mockUserCurrentOverviewListQuery } from '../graphql/queries/userCurrentOverviewList.mocks.ts'
import { getUserCurrentOverviewOrderingUpdatesSubscriptionHandler } from '../graphql/subscriptions/userCurrentOverviewOrderingUpdates.mocks.ts'

const userCurrentOverviewList = [
  {
    id: convertToGraphQLId('Overview', 1),
    name: 'Open Tickets',
  },
  {
    id: convertToGraphQLId('Overview', 2),
    name: 'My Tickets',
  },
  {
    id: convertToGraphQLId('Overview', 3),
    name: 'All Tickets',
  },
]

const userCurrentOverviewListAferReset = userCurrentOverviewList.reverse()

describe('personal settings for token access', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })
    mockPermissions(['user_preferences.overview_sorting'])
  })

  it('shows the overviews order by priority', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentOverviewList })

    const view = await visitView('/personal-setting/ticket-overviews')

    const overviewContainer = view.getByLabelText('Order of ticket overviews')

    const overviews = getAllByRole(overviewContainer, 'listitem')

    userCurrentOverviewList.forEach((overview, index) => {
      expect(overviews[index]).toHaveTextContent(overview.name)
    })
  })

  // TODO: Cover the update of overview order when the items are moved around the list.
  //   We may need to implement a testable mechanism for reordering the list, though, as drag events are not fully
  //   supported in JSDOM due to missing client-rectangle coordinate mocking.
  //   One approach could be to add keyboard shortcuts for changing the order, or perhaps even hidden buttons.

  it('allows to reset the order of overviews', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentOverviewList })

    const view = await visitView('/personal-setting/ticket-overviews')

    mockUserCurrentOverviewResetOrderMutation({
      userCurrentOverviewResetOrder: {
        success: true,
        overviews: userCurrentOverviewListAferReset,
        errors: null,
      },
    })

    const resetButton = view.getByRole('button', {
      name: 'Reset Overview Order',
    })

    expect(resetButton).toBeInTheDocument()

    await view.events.click(resetButton)

    await waitForNextTick()

    expect(
      await view.findByRole('dialog', { name: 'Confirmation' }),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Yes' }))

    await waitForNextTick()

    userCurrentOverviewListAferReset.forEach((overview) => {
      expect(view.getByText(overview.name)).toBeInTheDocument()
    })
  })

  it('updates the overviews list when a new overview is added', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentOverviewList })

    const view = await visitView('/personal-setting/ticket-overviews')

    const overviewUpdateSubscription =
      getUserCurrentOverviewOrderingUpdatesSubscriptionHandler()

    userCurrentOverviewList.forEach((overview) => {
      expect(view.getByText(overview.name)).toBeInTheDocument()
    })

    overviewUpdateSubscription.trigger({
      userCurrentOverviewOrderingUpdates: {
        overviews: [
          ...userCurrentOverviewList,
          {
            id: convertToGraphQLId('Overview', 4),
            name: 'New Overview',
          },
        ],
      },
    })

    await waitForNextTick()

    expect(view.getByText('New Overview')).toBeInTheDocument()
  })
})
