// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { TicketsByOverviewQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { mock } from 'vitest-mock-extended'
import { TicketsByOverviewDocument } from '../../graphql/queries/ticketsByOverview.api'

type TicketItemByOverview = ConfidentTake<
  TicketsByOverviewQuery,
  'ticketsByOverview.edges.node'
>

type TicketByOverviewPageInfo = ConfidentTake<
  TicketsByOverviewQuery,
  'ticketsByOverview.pageInfo'
>

const ticketDate = new Date(2022, 0, 29, 0, 0, 0, 0)

export const ticketDefault: Partial<TicketItemByOverview> = {
  id: 'af12',
  title: 'Ticket 1',
  number: '63001',
  internalId: 1,
  createdAt: ticketDate.toISOString(),
  priority: {
    id: 'fdsf214fse12e',
    name: 'high',
    defaultCreate: false,
  },
  customer: {
    id: 'fdsf214fse12d',
    firstname: 'John',
    lastname: 'Doe',
    fullname: 'John Doe',
  },
}

export const mockTicketsByOverview = (
  tickets: Partial<TicketItemByOverview>[] = [ticketDefault],
  pageInfo: Partial<TicketByOverviewPageInfo> = {},
  totalCount: number | null = null,
) => {
  return mockGraphQLApi(TicketsByOverviewDocument).willResolve(
    mock<TicketsByOverviewQuery>(
      {
        ticketsByOverview: {
          totalCount: totalCount ?? tickets.length,
          edges: tickets.map((node) => ({ node })),
          pageInfo,
        },
      },
      { deep: true },
    ),
  )
}
