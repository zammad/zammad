// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor, within } from '@testing-library/vue'
import { expect } from 'vitest'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  mockTicketUpdateMutation,
  waitForTicketUpdateMutationCalls,
} from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketScreenBehavior } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { getUserCurrentTaskbarItemUpdatesSubscriptionHandler } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTaskbarItemUpdates.mocks.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view screen behavior', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  it('closes ticket tab after ticket update', async () => {
    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    mockUserCurrent({
      preferences: {
        secondaryAction: EnumTicketScreenBehavior.CloseTab,
      },
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

    // Simulate the history stack by visiting another (different) route before the current one.
    const view = await visitView('/tickets/2')

    const router = getTestRouter()
    await router.push('/tickets/1')

    expect(router.currentRoute.value.path).toEqual('/tickets/1')

    await getNode('form-ticket-edit')?.settled

    await view.events.click(view.getByRole('button', { name: 'Update' }))

    await waitForTicketUpdateMutationCalls()

    // Make sure the user is redirected to the previous route after the tab was closed.
    await waitFor(() =>
      expect(router.currentRoute.value.path).toEqual('/tickets/2'),
    )
  })

  it('closes tab on ticket close after ticket update', async () => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })

    const ticket = createDummyTicket({
      state: {
        id: convertToGraphQLId('Ticket::State', 2),
        name: 'open',
        stateType: {
          id: convertToGraphQLId('TicketStateType', 2),
          name: 'open',
        },
      },
      defaultPolicy: {
        update: true,
        agentReadAccess: true,
      },
    })

    mockTicketQuery({
      ticket,
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

    const view = await visitView('/tickets/1')

    await getNode('form-ticket-edit')?.settled

    const ticketMetaSidebar = within(view.getByLabelText('Content sidebar'))

    await view.events.click(await ticketMetaSidebar.findByLabelText('State'))

    expect(
      await view.findByRole('listbox', { name: 'Select…' }),
    ).toBeInTheDocument()

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          state_id: { value: 4 },
        },
      },
    })
    await view.events.click(view.getByRole('option', { name: 'closed' }))

    await getNode('form-ticket-edit')?.settled

    mockTicketUpdateMutation({
      ticketUpdate: {
        ticket: {
          ...ticket,
          state: {
            ...ticket.state,
            id: convertToGraphQLId('Ticket::State', 4),
            name: 'closed',
            stateType: {
              ...ticket.state.stateType,
              id: convertToGraphQLId('Ticket::StateType', 5),
              name: 'closed',
            },
          },
        },
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Update' }))

    await getUserCurrentTaskbarItemUpdatesSubscriptionHandler().trigger({
      userCurrentTaskbarItemUpdates: {
        updateItem: null,
        addItem: null,
        removeItem: convertToGraphQLId('Taskbar', 1),
      },
    })

    const router = getTestRouter()

    await waitForTicketUpdateMutationCalls()

    // TODO: Test for a real redirect once the overview is implemented.
    await waitFor(() =>
      expect(router.currentRoute.value.path).not.toEqual('/tickets/1'),
    )
  })

  it('stays on tab after ticket update', async () => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [],
    })

    const ticket = createDummyTicket({
      defaultPolicy: {
        update: true,
        agentReadAccess: true,
      },
    })

    mockTicketQuery({
      ticket,
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

    const view = await visitView('/tickets/1')

    await getNode('form-ticket-edit')?.settled

    await view.events.click(view.getByRole('button', { name: 'Update' }))

    expect(
      await view.findByText('Ticket updated successfully.'),
    ).toBeInTheDocument()

    const router = getTestRouter()

    expect(router.currentRoute.value.path).toEqual('/tickets/1')
  })

  it.todo('redirects to overview after ticket update', async () => {
    // :TODO add test as soon as we have overview implemented
  })
})
