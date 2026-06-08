// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumOrderDirection,
  type Overview,
  type TicketsCachedByOverviewQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { mockOverviewsWithCachedCountQuery } from '#desktop/entities/ticket/graphql/queries/overviewsWithCachedCount.mocks.ts'
import { mockTicketsCachedByOverviewQuery } from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.mocks.ts'
import { mockUserCurrentTicketOverviewsQuery } from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.mocks.ts'

export const getDefaultOverviews = () => [
  {
    id: convertToGraphQLId('Overview', 1),
    name: 'My Assigned Tickets',
    link: 'my_assigned',
    prio: 1000,
    orderBy: 'created_at',
    orderDirection: EnumOrderDirection.Ascending,
    viewColumns: [],
    orderColumns: [],
    active: true,
  },
  {
    id: convertToGraphQLId('Overview', 2),
    name: 'New Tickets',
    link: 'new_tickets',
    prio: 2000,
    orderBy: 'created_at',
    orderDirection: EnumOrderDirection.Ascending,
    viewColumns: [],
    orderColumns: [],
    active: true,
  },
]

export const mockDefaultOverviewQueries = (overviews?: DeepPartial<Overview>[]): void => {
  const usedOverviews = overviews ?? getDefaultOverviews()

  mockUserCurrentTicketOverviewsQuery({
    userCurrentTicketOverviews: usedOverviews,
  })

  mockOverviewsWithCachedCountQuery({
    ticketOverviews: usedOverviews,
  })
}

export const mockDefaultTicketsCachedByOverview = (
  options: DeepPartial<TicketsCachedByOverviewQuery['ticketsCachedByOverview']> = {},
): void => {
  const {
    edges = [
      {
        __typename: 'TicketEdge',
        node: createDummyTicket(),
        cursor: 'cursor-0',
      },
    ],
    totalCount = options.edges?.length,
    pageInfo = {
      endCursor: 'MjU',
      hasNextPage: false,
    },
  } = options

  const ticketsCachedByOverview = generateObjectData('CachedTicketConnection', {
    totalCount,
    edges,
    pageInfo,
  })

  mockTicketsCachedByOverviewQuery({ ticketsCachedByOverview })
}

export const mockEmptyTicketsCachedByOverview = (): void => {
  mockDefaultTicketsCachedByOverview({
    edges: [],
    totalCount: 0,
  })
}
