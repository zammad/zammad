// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { visitView } from '#tests/support/components/visitView.ts'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import { ObjectManagerFrontendAttributesDocument } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api.ts'
import { UserUpdatesDocument } from '#shared/graphql/subscriptions/userUpdates.api.ts'
import type { TicketQuery } from '#shared/graphql/types.ts'

import { ticketObjectAttributes } from '#mobile/entities/ticket/__tests__/mocks/ticket-mocks.ts'
import {
  mockUserGql,
  userObjectAttributes,
} from '#mobile/entities/user/__tests__/mocks/user-mocks.ts'

import { defaultTicket, mockTicketDetailViewGql } from './mocks/detail-view.ts'

vi.hoisted(() => {
  const now = new Date(2022, 1, 1, 0, 0, 0, 0)
  vi.setSystemTime(now)
})

// Vitest has a bug where vi.hoisted is not hoisted if there is no vi.mock
// TODO: remove when updating to Vitest 1.0
vi.mock('./non-existing.js')

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

    await expect(view.findByText('Confirm dialog')).resolves.toBeInTheDocument()
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

describe('rendering escalation times', () => {
  const yesterday = new Date(2022, 1, 0, 0, 0, 0, 0)
  const tomorrow = new Date(2022, 1, 2, 0, 0, 0, 0)

  const regions = ['First Response Time', 'Update Time', 'Solution Time']

  const escalatedClasses = 'text-red-bright bg-red-highlight'
  const warningClasses = 'text-yellow bg-yellow-highlight'

  it.each([
    {
      name: 'all',
      dates: [yesterday, yesterday, tomorrow],
      escalated: [true, true, false],
      labels: ['1 day ago', '1 day ago', 'in 1 day'],
    },
    {
      name: 'partial',
      dates: [yesterday, null, tomorrow],
      escalated: [true, null, false],
      labels: ['1 day ago', null, 'in 1 day'],
    },
  ])(
    'renders escalation time - $name',
    async ({ dates, escalated, labels }) => {
      const ticket = defaultTicket()
      ticket.ticket.firstResponseEscalationAt = dates[0]?.toISOString() ?? null
      ticket.ticket.updateEscalationAt = dates[1]?.toISOString() ?? null
      ticket.ticket.closeEscalationAt = dates[2]?.toISOString() ?? null

      const { view } = await visitTicketInformation(ticket)

      expect(view.getByText('Escalation Times')).toBeInTheDocument()

      regions.forEach((region, index) => {
        if (dates[index] === null) {
          expect(
            view.queryByRole('region', { name: region }),
          ).not.toBeInTheDocument()
          return
        }

        const responseTime = view.getByRole('region', { name: region })
        const classes = escalated[index] ? escalatedClasses : warningClasses

        expect(responseTime).toHaveTextContent(labels[index]!)
        expect(responseTime.parentElement).toHaveClass(classes)
      })
    },
  )

  it("doesn't render escalation time if it's not provided", async () => {
    const ticket = defaultTicket()
    ticket.ticket.closeEscalationAt = null
    ticket.ticket.firstResponseEscalationAt = null
    ticket.ticket.updateEscalationAt = null

    const { view } = await visitTicketInformation(ticket)

    expect(view.queryByText('Escalation Times')).not.toBeInTheDocument()
    regions.forEach((region) => {
      expect(
        view.queryByRole('region', { name: region }),
      ).not.toBeInTheDocument()
    })
  })
})
