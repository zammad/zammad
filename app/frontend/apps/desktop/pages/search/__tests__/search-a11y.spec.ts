// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  EnumSearchableModels,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockDetailSearchQuery } from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'
import { mockSearchCountsQuery } from '#desktop/components/Search/graphql/queries/searchCounts.mocks.ts'

describe('search view', () => {
  it('has no accessibility violations in main content', async () => {
    mockPermissions(['ticket.agent'])

    mockSearchCountsQuery({
      searchCounts: [
        {
          model: EnumSearchableModels.User,
          totalCount: 111,
        },
        {
          model: EnumSearchableModels.Organization,
          totalCount: 222,
        },
      ],
    })

    mockDetailSearchQuery({
      search: {
        totalCount: 1,
        items: [
          {
            title: 'Ticket 1',
            id: convertToGraphQLId('Ticket', 1),
            internalId: 1,
            customer: {
              id: convertToGraphQLId('User', 2),
              fullname: 'Nicole Braun User',
            },
            group: {
              id: convertToGraphQLId('Group', 6),
              name: 'Group 1',
            },
            state: {
              id: convertToGraphQLId('State', 2),
              name: 'open',
            },
            stateColorCode: EnumTicketStateColorCode.Open,
            priority: {
              id: convertToGraphQLId('TicketPriority', 2),
              name: '2 normal',
              uiColor: null,
            },
            createdAt: '2025-02-20T10:21:14Z',
            __typename: 'Ticket',
          },
        ],
      },
    })

    const view = await visitView('/search')

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })
})
