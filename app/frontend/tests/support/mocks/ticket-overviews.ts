// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { OverviewsDocument } from '@shared/entities/ticket/graphql/queries/overviews.api'
import { OverviewsQuery } from '@shared/graphql/types'
import { mock } from 'vitest-mock-extended'
import { mockGraphQLApi } from '../mock-graphql-api'

export const getApiTicketOverviews = (): OverviewsQuery => ({
  overviews: mock<OverviewsQuery['overviews']>(
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
          },
        },
        {
          cursor: 'node2',
          node: {
            id: '2',
            name: __('Overview 2'),
            link: 'overview_2',
            ticketCount: 2,
          },
        },
        {
          cursor: 'node3',
          node: {
            id: '3',
            name: __('Overview 3'),
            link: 'overview_3',
            ticketCount: 3,
          },
        },
      ],
    },
    { deep: true },
  ),
})

export const mockTicketOverviews = () => {
  return mockGraphQLApi(OverviewsDocument).willResolve(getApiTicketOverviews())
}
