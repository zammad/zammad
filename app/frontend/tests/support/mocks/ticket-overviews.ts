// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketOverviewOrderQuery, TicketOverviewsQuery } from '#shared/graphql/types.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'

import { TicketOverviewOrderDocument } from '#mobile/entities/ticket/graphql/queries/overviewOrder.api.ts'
import { TicketOverviewsDocument } from '#mobile/entities/ticket/graphql/queries/overviews.api.ts'
import { TicketOverviewUpdatesDocument } from '#mobile/entities/ticket/graphql/subscriptions/ticketOverviewUpdates.api.ts'

import { mockGraphQLApi, mockGraphQLSubscription } from '../mock-graphql-api.ts'

const column = (key: string, value: string) => ({
  __typename: 'KeyValue' as const,
  key,
  value,
})

export const getApiTicketOverviews = (): TicketOverviewsQuery => ({
  ticketOverviews: [
    {
      __typename: 'Overview',
      id: '1',
      internalId: 1,
      name: __('Overview 1'),
      link: 'overview_1',
      ticketCount: 1,
      orderBy: 'created_at',
      orderDirection: EnumOrderDirection.Descending,
      organizationShared: false,
      outOfOffice: false,
      prio: 100,
      active: true,
      viewColumns: [
        column('number', 'Number'),
        column('title', 'Title'),
        column('created_at', 'Created at'),
        column('updated_at', 'Updated at'),
        column('priority', 'Priority'),
      ],
      orderColumns: [
        column('number', 'Number'),
        column('title', 'Title'),
        column('created_at', 'Created at'),
        column('updated_at', 'Updated at'),
      ],
      groupBy: null,
    },
    {
      __typename: 'Overview',
      id: '2',
      internalId: 2,
      name: __('Overview 2'),
      link: 'overview_2',
      ticketCount: 2,
      orderBy: 'created_at',
      orderDirection: EnumOrderDirection.Ascending,
      organizationShared: false,
      outOfOffice: false,
      prio: 200,
      active: true,
      viewColumns: [
        column('number', 'Number'),
        column('title', 'Title'),
        column('created_at', 'Created at'),
        column('updated_at', 'Updated at'),
      ],
      orderColumns: [
        column('number', 'Number'),
        column('title', 'Title'),
        column('created_at', 'Created at'),
        column('updated_at', 'Updated at'),
      ],
      groupBy: null,
    },
    {
      __typename: 'Overview',
      id: '3',
      internalId: 3,
      name: __('Overview 3'),
      link: 'overview_3',
      ticketCount: 3,
      orderBy: 'created_at',
      orderDirection: EnumOrderDirection.Ascending,
      organizationShared: false,
      outOfOffice: false,
      prio: 300,
      active: true,
      viewColumns: [
        column('number', 'Number'),
        column('title', 'Title'),
        column('created_at', 'Created at'),
        column('updated_at', 'Updated at'),
      ],
      orderColumns: [
        column('number', 'Number'),
        column('title', 'Title'),
        column('created_at', 'Created at'),
        column('updated_at', 'Updated at'),
      ],
      groupBy: null,
    },
  ],
})

export const mockTicketOverviews = (overviews?: TicketOverviewsQuery) => {
  mockGraphQLSubscription(TicketOverviewUpdatesDocument)

  return mockGraphQLApi(TicketOverviewsDocument).willResolve(overviews || getApiTicketOverviews())
}

export const mockTicketOverviewOrder = (overviews?: TicketOverviewOrderQuery) => {
  mockGraphQLSubscription(TicketOverviewUpdatesDocument)

  return mockGraphQLApi(TicketOverviewOrderDocument).willResolve(
    overviews || getApiTicketOverviews(),
  )
}
