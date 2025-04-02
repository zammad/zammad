// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type {
  TicketOverviewOrderQuery,
  TicketOverviewsQuery,
} from '#shared/graphql/types.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'

import { TicketOverviewOrderDocument } from '#mobile/entities/ticket/graphql/queries/overviewOrder.api.ts'
import { TicketOverviewsDocument } from '#mobile/entities/ticket/graphql/queries/overviews.api.ts'
import { TicketOverviewUpdatesDocument } from '#mobile/entities/ticket/graphql/subscriptions/ticketOverviewUpdates.api.ts'

import { mockGraphQLApi, mockGraphQLSubscription } from '../mock-graphql-api.ts'

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
        { key: 'number', value: 'Number' },
        { key: 'title', value: 'Title' },
        { key: 'created_at', value: 'Created at' },
        { key: 'updated_at', value: 'Updated at' },
        { key: 'priority', value: 'Priority' },
      ],
      orderColumns: [
        { key: 'number', value: 'Number' },
        { key: 'title', value: 'Title' },
        { key: 'created_at', value: 'Created at' },
        { key: 'updated_at', value: 'Updated at' },
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
        { key: 'number', value: 'Number' },
        { key: 'title', value: 'Title' },
        { key: 'created_at', value: 'Created at' },
        { key: 'updated_at', value: 'Updated at' },
      ],
      orderColumns: [
        { key: 'number', value: 'Number' },
        { key: 'title', value: 'Title' },
        { key: 'created_at', value: 'Created at' },
        { key: 'updated_at', value: 'Updated at' },
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
        { key: 'number', value: 'Number' },
        { key: 'title', value: 'Title' },
        { key: 'created_at', value: 'Created at' },
        { key: 'updated_at', value: 'Updated at' },
      ],
      orderColumns: [
        { key: 'number', value: 'Number' },
        { key: 'title', value: 'Title' },
        { key: 'created_at', value: 'Created at' },
        { key: 'updated_at', value: 'Updated at' },
      ],
      groupBy: null,
    },
  ],
})

export const mockTicketOverviews = (overviews?: TicketOverviewsQuery) => {
  mockGraphQLSubscription(TicketOverviewUpdatesDocument)

  return mockGraphQLApi(TicketOverviewsDocument).willResolve(
    overviews || getApiTicketOverviews(),
  )
}

export const mockTicketOverviewOrder = (
  overviews?: TicketOverviewOrderQuery,
) => {
  mockGraphQLSubscription(TicketOverviewUpdatesDocument)

  return mockGraphQLApi(TicketOverviewOrderDocument).willResolve(
    overviews || getApiTicketOverviews(),
  )
}
