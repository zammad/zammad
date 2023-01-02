// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { TicketOverviewsDocument } from '@shared/entities/ticket/graphql/queries/ticket/overviews.api'
import type { TicketOverviewsQuery } from '@shared/graphql/types'
import { EnumOrderDirection } from '@shared/graphql/types'
import { mockGraphQLApi } from '../mock-graphql-api'

export const getApiTicketOverviews = (): TicketOverviewsQuery => ({
  ticketOverviews: {
    pageInfo: {
      endCursor: null,
      hasNextPage: false,
    },
    edges: [
      {
        cursor: 'node1',
        node: {
          id: '1',
          name: __('Overview 1'),
          link: 'overview_1',
          ticketCount: 1,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Descending,
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
        },
      },
      {
        cursor: 'node2',
        node: {
          id: '2',
          name: __('Overview 2'),
          link: 'overview_2',
          ticketCount: 2,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Ascending,
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
        },
      },
      {
        cursor: 'node3',
        node: {
          id: '3',
          name: __('Overview 3'),
          link: 'overview_3',
          ticketCount: 3,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Ascending,
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
        },
      },
    ],
  },
})

export const mockTicketOverviews = (overviews?: TicketOverviewsQuery) => {
  return mockGraphQLApi(TicketOverviewsDocument).willResolve(
    overviews || getApiTicketOverviews(),
  )
}
