// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import {
  mockTicketsByOverview,
  ticketDefault,
} from '@mobile/modules/ticket/__tests__/mocks/overview'
import { EnumOrderDirection } from '@shared/graphql/types'
import { renderComponent } from '@tests/support/components'
import { waitUntil } from '@tests/support/utils'
import TicketList from '../TicketList.vue'

describe('testing a list of tickets', () => {
  it('shows warning when all available tickets are loaded', async () => {
    const ticketOverviewsApi = mockTicketsByOverview(
      [ticketDefault],
      {
        hasNextPage: true,
        endCursor: 'cursor',
      },
      10,
    )

    const view = renderComponent(TicketList, {
      props: {
        maxCount: 1,
        overviewId: '1f',
        orderBy: 'name',
        orderDirection: EnumOrderDirection.Ascending,
      },
      router: true,
      store: true,
    })

    await waitUntil(() => ticketOverviewsApi.spies.resolve.mock.calls.length)

    expect(
      view.getByText('The limit of 1 tickets reached (9 remaining)'),
    ).toBeInTheDocument()
  })
})
