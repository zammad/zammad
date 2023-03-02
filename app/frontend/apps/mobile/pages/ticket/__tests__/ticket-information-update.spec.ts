// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ticketObjectAttributes } from '@mobile/entities/ticket/__tests__/mocks/ticket-mocks'
import { FormUpdaterDocument } from '@shared/components/Form/graphql/queries/formUpdater.api'
import { visitView } from '@tests/support/components/visitView'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { ObjectManagerFrontendAttributesDocument } from '@shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api'
import { waitUntil } from '@tests/support/utils'
import { getNode } from '@formkit/core'
import {
  mockUserGql,
  userObjectAttributes,
} from '@mobile/entities/user/__tests__/mocks/user-mocks'
import { UserUpdatesDocument } from '@shared/graphql/subscriptions/userUpdates.api'
import { mockPermissions } from '@tests/support/mock-permissions'
import type { TicketQuery } from '@shared/graphql/types'
import { mockTicketDetailViewGql } from './mocks/detail-view'

const visitTicketInformation = async (ticket?: TicketQuery) => {
  mockPermissions(['ticket.agent'])
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
  const { mockApiTicket } = mockTicketDetailViewGql({ ticket })
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
  it('shows confirm popup, when leaving', async () => {
    const { view } = await visitTicketInformation()

    await getNode('form-ticket-edit')?.settled

    await view.events.type(view.getByLabelText('Ticket title'), '55')

    await getNode('form-ticket-edit')?.settled

    const { mockUser } = mockUserGql()
    mockGraphQLSubscription(UserUpdatesDocument)

    await view.events.click(view.getByRole('tab', { name: 'Customer' }))

    await waitUntil(() => mockUser.calls.resolve)

    await view.events.click(view.getByRole('link', { name: 'open 4' }))

    await expect(
      view.findByRole('alert', { name: 'Confirm dialog' }),
    ).resolves.toBeInTheDocument()
  })

  it('show save banner when some field was changed', async () => {
    const { view } = await visitTicketInformation()

    await getNode('form-ticket-edit')?.settled

    await view.events.type(view.getByLabelText('Ticket title'), 'New title')

    await getNode('form-ticket-edit')?.settled

    await expect(
      view.findByRole('button', { name: 'Save' }),
    ).resolves.toBeInTheDocument()
  })

  it('show save banner with error indicator when one field is invalid (and error message after save click)', async () => {
    const { view } = await visitTicketInformation()

    await getNode('form-ticket-edit')?.settled

    await view.events.clear(view.getByLabelText('Ticket title'))

    await getNode('form-ticket-edit')?.settled

    await expect(
      view.findByLabelText('Validation failed'),
    ).resolves.toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Save' }))

    expect(view.getByText('This field is required.')).toBeInTheDocument()
  })

  // since most of it is core workflow + backend, it's tested in the backend
})
