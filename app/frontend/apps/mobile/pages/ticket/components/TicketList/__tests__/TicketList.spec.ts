// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { EnumOrderDirection } from '#shared/graphql/types.ts'

import {
  mockTicketsByOverview,
  ticketDefault,
} from '#mobile/pages/ticket/__tests__/mocks/overview.ts'

import TicketList from '../TicketList.vue'

describe('testing a list of tickets', () => {
  it('shows warning when all available tickets are loaded', async () => {
    const ticketOverviewsApi = mockTicketsByOverview(
      [ticketDefault()],
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
        hiddenColumns: [],
      },
      form: true,
      formField: true,
      router: true,
      store: true,
    })

    await waitUntil(() => ticketOverviewsApi.spies.resolve.mock.calls.length)

    expect(
      view.getByText(
        'The limit of 1 displayable tickets was reached (9 remaining)',
      ),
    ).toBeInTheDocument()
  })
})
