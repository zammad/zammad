// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'
import { mockTicketHistoryQuery } from '../../graphql/queries/ticketHistory.mocks.ts'

describe('Ticket detail view - history', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'Adam',
      lastname: 'Doe',
    })

    mockPermissions(['ticket.agent'])
  })

  it('displays history', async () => {
    const ticket = createDummyTicket()

    mockTicketQuery({ ticket })

    const view = await visitView('/tickets/1')

    await waitForNextTick()

    mockLinkListQuery({
      linkList: [],
    })

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
                id: 'gid://zammad/User/2',
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

    const sidebar = view.getByLabelText('Content sidebar')

    await view.events.click(
      within(sidebar).getByRole('button', { name: 'Action menu button' }),
    )

    await view.events.click(
      await view.findByRole('button', { name: 'History' }),
    )

    await waitForNextTick()

    expect(
      await view.findByRole('heading', { name: 'Ticket History', level: 2 }),
    ).toBeInTheDocument()

    const flyout = view.getByRole('complementary', {
      name: 'Ticket History',
    })

    await waitFor(() =>
      expect(within(flyout).getByText('Created')).toBeInTheDocument(),
    )

    expect(within(flyout).getByText('Created')).toBeInTheDocument()
    expect(within(flyout).getByText('John Doe')).toBeInTheDocument()
    expect(within(flyout).getByText('2021-09-29 14:00')).toBeInTheDocument()
  })
})
