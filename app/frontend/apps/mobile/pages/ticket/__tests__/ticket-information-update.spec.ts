// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ticketObjectAttributes } from '@mobile/entities/ticket/__tests__/mocks/ticket-mocks'
import { FormUpdaterDocument } from '@shared/components/Form/graphql/queries/formUpdater.api'
import { visitView } from '@tests/support/components/visitView'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { ObjectManagerFrontendAttributesDocument } from '@shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api'
import { waitUntil } from '@tests/support/utils'
import { waitFor } from '@testing-library/vue'
import {
  mockUserGql,
  userObjectAttributes,
} from '@mobile/entities/user/__tests__/mocks/user-mocks'
import { UserUpdatesDocument } from '@shared/graphql/subscriptions/userUpdates.api'
import { mockTicketGql } from './mocks/detail-view'

const visitTicketInformation = async () => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willBehave(
    ({ object }) => {
      if (object === 'Ticket') {
        return {
          data: { objectManagerFrontendAttributes: ticketObjectAttributes() },
        }
      }
      return {
        data: { objectManagerFrontendAttributes: userObjectAttributes() },
      }
    },
  )
  const { mockApiTicket } = mockTicketGql()
  mockGraphQLApi(FormUpdaterDocument).willResolve({
    formUpdater: {
      group_id: {
        show: true,
        options: [
          {
            label: 'Users',
            value: 1,
          },
        ],
        clearable: true,
      },
      owner_id: {
        show: true,
        options: [{ value: 100, label: 'Max Mustermann' }],
      },
      priority_id: {
        show: true,
        options: [
          { value: 1, label: '1 low' },
          { value: 2, label: '2 normal' },
          { value: 3, label: '3 high' },
        ],
        clearable: true,
      },
      pending_time: {
        show: false,
        required: false,
        hidden: false,
        disabled: false,
      },
      state_id: {
        show: true,
        options: [
          { value: 4, label: 'closed' },
          { value: 2, label: 'open' },
          { value: 7, label: 'pending close' },
          { value: 3, label: 'pending reminder' },
        ],
        clearable: true,
      },
    },
  })
  const view = await visitView('/tickets/1/information')
  await waitUntil(() => mockApiTicket.calls.resolve)
  return { view }
}

describe('updating ticket information', () => {
  it("doesn't show 'save' button, if user has no rights to update a ticket", async () => {
    mockPermissions([])
    const { view } = await visitTicketInformation()
    expect(
      view.queryByRole('button', { name: 'Save ticket' }),
    ).not.toBeInTheDocument()
  })

  it('title has focus', async () => {
    mockPermissions(['ticket.agent'])
    const { view } = await visitTicketInformation()

    expect(view.getByLabelText('Ticket title')).toHaveFocus()

    const { mockUser } = mockUserGql()
    mockGraphQLSubscription(UserUpdatesDocument)

    await view.events.click(view.getByRole('tab', { name: 'Customer' }))

    await waitUntil(() => mockUser.calls.resolve)

    await view.events.click(view.getByRole('tab', { name: 'Ticket' }))

    await waitFor(() => {
      expect(view.getByLabelText('Ticket title')).toHaveFocus()
    })
  })

  it('shows confirm popup, when leaving', async () => {
    mockPermissions(['ticket.agent'])
    const { view } = await visitTicketInformation()

    await view.events.type(view.getByLabelText('Ticket title'), '55')

    const { mockUser } = mockUserGql()
    mockGraphQLSubscription(UserUpdatesDocument)

    await view.events.click(view.getByRole('tab', { name: 'Customer' }))

    await waitUntil(() => mockUser.calls.resolve)

    await view.events.click(view.getByRole('link', { name: 'open 4' }))

    expect(
      view.findByRole('alert', { name: 'Confirm dialog' }),
    ).resolves.toBeInTheDocument()
  })

  // since most of it is core workflow + backend, it's tested in the backend
})
