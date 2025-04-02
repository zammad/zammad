// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { nullableMock } from '#tests/support/utils.ts'

import {
  EnumTicketStateColorCode,
  type TicketsByOverviewSlimQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import { TicketsByOverviewSlimDocument } from '../../graphql/queries/ticketsByOverviewSlim.api.ts'

type TicketItemByOverviewSlim = ConfidentTake<
  TicketsByOverviewSlimQuery,
  'ticketsByOverview.edges.node'
>

type TicketByOverviewPageInfo = ConfidentTake<
  TicketsByOverviewSlimQuery,
  'ticketsByOverview.pageInfo'
>

const ticketDate = new Date(2022, 0, 29, 0, 0, 0, 0)

export const ticketDefault = () =>
  nullableMock<TicketItemByOverviewSlim>({
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
        id: convertToGraphQLId('TicketStateType', '2'),
        name: 'open',
      },
    },
    priority: {
      __typename: 'TicketPriority',
      id: 'fdsf214fse12e',
      name: 'high',
      defaultCreate: true,
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
    stateColorCode: EnumTicketStateColorCode.Open,
  })

export const mockTicketsByOverview = (
  tickets: Partial<TicketItemByOverviewSlim>[] = [ticketDefault()],
  pageInfo: Partial<TicketByOverviewPageInfo> = {},
  totalCount: number | null = null,
) => {
  return mockGraphQLApi(
    TicketsByOverviewSlimDocument,
  ).willResolve<TicketsByOverviewSlimQuery>({
    ticketsByOverview: {
      __typename: 'TicketConnection',
      totalCount: totalCount ?? tickets.length,
      edges: tickets.map((node, index) => ({
        __typename: 'TicketEdge',
        node: nullableMock(node) as TicketItemByOverviewSlim,
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
