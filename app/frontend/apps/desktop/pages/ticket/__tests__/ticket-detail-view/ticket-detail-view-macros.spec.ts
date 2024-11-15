// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { expect } from 'vitest'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { mockMacrosQuery } from '#shared/graphql/queries/macros.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { getUserCurrentTaskbarItemUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTaskbarItemUpdates.mocks.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view macros', () => {
  it('executes example macro which closes current tab', async () => {
    mockPermissions(['ticket.agent'])

    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    mockLinkListQuery({
      linkList: [],
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: {
            options: [
              {
                value: 1,
                label: 'Users',
              },
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
              {
                value: 2,
                label: 'open',
              },
              {
                value: 6,
                label: 'pending close',
              },
              {
                value: 3,
                label: 'pending reminder',
              },
            ],
          },
          pending_time: {
            show: false,
          },
          priority_id: {
            options: [
              {
                value: 1,
                label: '1 low',
              },
              {
                value: 2,
                label: '2 normal',
              },
              {
                value: 3,
                label: '3 high',
              },
            ],
          },
        },
        flags: {
          newArticlePresent: false,
        },
      },
    })

    mockMacrosQuery({
      macros: [
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 1),
          active: true,
          name: 'Macro Foo',
          uxFlowNextUp: 'next_task',
        },
        {
          __typename: 'Macro',
          id: convertToGraphQLId('Macro', 2),
          active: true,
          name: 'Macro 2',
          uxFlowNextUp: 'next_task',
        },
      ],
    })

    const view = await visitView('/tickets/1')

    const actionMenu = await view.findByLabelText(
      'Additional ticket edit actions',
    )

    await view.events.click(actionMenu)

    const menu = await view.findByRole('menu')

    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        updateItem: null,
        addItem: null,
        removeItem: convertToGraphQLId('Taskbar', 1),
      },
    })

    await view.events.click(within(menu).getByText('Macro Foo'))

    const router = getTestRouter()

    // :TODO add this real redirect once the overview is implemented
    await waitFor(() =>
      expect(router.currentRoute.value.path).not.toEqual('/tickets/1'),
    )
  })
})
