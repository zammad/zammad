// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useTicketHistoryQuery } from '#desktop/pages/ticket/graphql/queries/ticketHistory.api.ts'
import { mockTicketHistoryQuery } from '#desktop/pages/ticket/graphql/queries/ticketHistory.mocks.ts'

import CommonHistoryFlyout from '../CommonHistoryFlyout.vue'

describe('CommonHistoryFlyout', () => {
  it('renders the history flyout with default title', () => {
    const ticketId = convertToGraphQLId('Ticket', 1)

    mockTicketHistoryQuery({
      ticketHistory: [],
    })

    const wrapper = renderComponent(CommonHistoryFlyout, {
      props: {
        name: 'test-history',
        type: EnumObjectManagerObjects.Ticket,
        query: () => useTicketHistoryQuery({ ticketId }),
      },
      flyout: true,
      store: true,
      router: true,
    })

    expect(wrapper.getByRole('heading', { name: 'History', level: 2 })).toBeInTheDocument()
  })

  it('renders the history flyout with custom title', () => {
    const ticketId = convertToGraphQLId('Ticket', 1)

    mockTicketHistoryQuery({
      ticketHistory: [],
    })

    const wrapper = renderComponent(CommonHistoryFlyout, {
      props: {
        name: 'test-history',
        type: EnumObjectManagerObjects.Ticket,
        query: () => useTicketHistoryQuery({ ticketId }),
        title: 'Custom History Title',
      },
      flyout: true,
      store: true,
      router: true,
    })

    expect(
      wrapper.getByRole('heading', { name: 'Custom History Title', level: 2 }),
    ).toBeInTheDocument()
  })

  it('renders the history entries', async () => {
    const ticketId = convertToGraphQLId('Ticket', 1)

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
                  object: {
                    __typename: 'Ticket',
                    id: ticketId,
                    internalId: 1,
                  },
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

    const wrapper = renderComponent(CommonHistoryFlyout, {
      props: {
        name: 'test-history',
        type: EnumObjectManagerObjects.Ticket,
        query: () => useTicketHistoryQuery({ ticketId }),
      },
      flyout: true,
      store: true,
    })

    await waitForNextTick()

    expect(wrapper.getByText('Created')).toBeInTheDocument()
    expect(wrapper.getByText('John Doe')).toBeInTheDocument()
  })
})
