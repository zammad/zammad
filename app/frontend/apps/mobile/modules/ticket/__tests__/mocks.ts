// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TicketsByOverviewQuery } from '@shared/graphql/types'
import { ConfidentTake } from '@shared/types/utils'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { mock } from 'vitest-mock-extended'
import { TicketsByOverviewDocument } from '../graphql/queries/ticketsByOverview.api'

type TicketItemByOverview = ConfidentTake<
  TicketsByOverviewQuery,
  'ticketsByOverview.edges.node'
>

type TicketByOverviewPageInfo = ConfidentTake<
  TicketsByOverviewQuery,
  'ticketsByOverview.pageInfo'
>

export const ticketDefault: Partial<TicketItemByOverview> = {
  id: 'af12',
  title: 'Ticket 1',
  number: '1',
  priority: {
    name: 'high',
    defaultCreate: false,
  },
  customer: {
    firstname: 'John',
    lastname: 'Doe',
    fullname: 'John Doe',
  },
}

export const mockTicketsByOverview = (
  tickets: Partial<TicketItemByOverview>[] = [ticketDefault],
  pageInfo: Partial<TicketByOverviewPageInfo> = {},
) => {
  return mockGraphQLApi(TicketsByOverviewDocument).willResolve(
    mock<TicketsByOverviewQuery>(
      {
        ticketsByOverview: {
          totalCount: tickets.length,
          edges: tickets.map((node) => ({ node })),
          pageInfo,
        },
      },
      { deep: true },
    ),
  )
}
