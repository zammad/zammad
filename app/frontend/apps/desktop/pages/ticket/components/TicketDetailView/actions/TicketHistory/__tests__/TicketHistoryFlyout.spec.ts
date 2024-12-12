// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockTicketHistoryQuery } from '#desktop/pages/ticket/graphql/queries/ticketHistory.mocks.ts'

import TicketHistoryFlyout from '../TicketHistoryFlyout.vue'

describe('TicketHistoryFlyout', () => {
  it('renders the ticket history flyout', () => {
    const wrapper = renderComponent(TicketHistoryFlyout, {
      props: { ticket: createDummyTicket() },
      flyout: true,
      store: true,
      router: true,
    })

    expect(
      wrapper.getByRole('heading', { name: 'Ticket History', level: 2 }),
    ).toBeInTheDocument()
  })

  it('renders the ticket history entries', async () => {
    const ticket = createDummyTicket()

    mockTicketHistoryQuery({
      ticketHistory: [
        {
          __typename: 'HistoryGroup',
          createdAt: '2021-09-29T14:00:00Z',
          records: [
            {
              __typename: 'HistoryRecord',
              events: [
                {
                  __typename: 'HistoryRecordEvent',
                  action: 'created',
                  createdAt: '2021-09-29T14:00:00Z',
                  object: ticket,
                },
              ],
              issuer: {
                __typename: 'User',
                id: convertToGraphQLId('User', 2),
                internalId: 2,
                firstname: 'John',
                lastname: 'Doe',
                fullname: 'John Doe',
              },
            },
          ],
        },
      ],
    })

    const wrapper = renderComponent(TicketHistoryFlyout, {
      props: { ticket },
      flyout: true,
      store: true,
    })

    await waitForNextTick()

    expect(wrapper.getByText('Created')).toBeInTheDocument()
    expect(wrapper.getByText('John Doe')).toBeInTheDocument()
    expect(wrapper.getByText('2021-09-29 14:00')).toBeInTheDocument()
  })
})
