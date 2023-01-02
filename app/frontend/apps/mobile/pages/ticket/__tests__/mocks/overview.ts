// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketsByOverviewQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { nullableMock } from '@tests/support/utils'
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

export const ticketDefault = () =>
  nullableMock<TicketItemByOverview>({
    __typename: 'Ticket',
    id: 'af12',
    title: 'Ticket 1',
    number: '63001',
    internalId: 1,
    createdAt: ticketDate.toISOString(),
    updatedAt: ticketDate.toISOString(),
    state: {
      __typename: 'TicketState',
      id: 'fsa234dsad2',
      name: 'open',
      stateType: {
        __typename: 'TicketStateType',
        name: 'open',
      },
    },
    priority: {
      __typename: 'TicketPriority',
      id: 'fdsf214fse12e',
      name: 'high',
      defaultCreate: false,
    },
    group: {
      __typename: 'Group',
      id: 'asc234d',
      name: 'open',
    },
    customer: {
      __typename: 'User',
      id: 'fdsf214fse12d',
      firstname: 'John',
      lastname: 'Doe',
      fullname: 'John Doe',
    },
  })

export const mockTicketsByOverview = (
  tickets: Partial<TicketItemByOverview>[] = [ticketDefault()],
  pageInfo: Partial<TicketByOverviewPageInfo> = {},
  totalCount: number | null = null,
) => {
  return mockGraphQLApi(
    TicketsByOverviewDocument,
  ).willResolve<TicketsByOverviewQuery>({
    ticketsByOverview: {
      __typename: 'TicketConnection',
      totalCount: totalCount ?? tickets.length,
      edges: tickets.map((node, index) => ({
        __typename: 'TicketEdge',
        node: nullableMock(node) as TicketItemByOverview,
        cursor: `node${index}`,
      })),
      pageInfo: {
        __typename: 'PageInfo',
        hasNextPage: true,
        endCursor: 'node1',
        ...pageInfo,
      },
    },
  })
}
