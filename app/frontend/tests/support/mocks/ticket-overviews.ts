// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TicketOverviewsDocument } from '@shared/entities/ticket/graphql/queries/ticket/overviews.api'
import type { TicketOverviewsQuery } from '@shared/graphql/types'
import { EnumOrderDirection } from '@shared/graphql/types'
import { mock } from 'vitest-mock-extended'
import { mockGraphQLApi } from '../mock-graphql-api'

export const getApiTicketOverviews = (): TicketOverviewsQuery => ({
  ticketOverviews: mock<TicketOverviewsQuery['ticketOverviews']>(
    {
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
    { deep: true },
  ),
})

export const mockTicketOverviews = () => {
  return mockGraphQLApi(TicketOverviewsDocument).willResolve(
    getApiTicketOverviews(),
  )
}
