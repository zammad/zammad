// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { axe } from 'vitest-axe'

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import ticketCustomerObjectAttributes from '#tests/graphql/factories/fixtures/ticket-customer-object-attributes.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockTicketsCachedByOverviewQuery } from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.mocks.ts'
import { mockUserCurrentTicketOverviewsQuery } from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.mocks.ts'

describe('ticket overviews view', () => {
  it('has no accessibility violations in main content', async () => {
    mockPermissions(['ticket.agent'])

    mockUserCurrentTicketOverviewsQuery({
      userCurrentTicketOverviews: [
        {
          id: convertToGraphQLId('Overview', 1),
          name: 'My Assigned Tickets',
          link: 'my_assigned',
          prio: 1000,
          orderBy: 'created_at',
          orderDirection: EnumOrderDirection.Ascending,
          viewColumnsRaw: [],
          active: true,
        },
      ],
    })

    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: ticketCustomerObjectAttributes(),
    })

    mockTicketsCachedByOverviewQuery({
      ticketsCachedByOverview: generateObjectData('TicketConnection', {
        edges: [
          {
            node: createDummyTicket(),
            cursor: 'MjY',
          },
        ],
        pageInfo: {
          endCursor: 'MjY',
          hasNextPage: false,
        },
      }),
    })

    const view = await visitView('/tickets/my_assigned')

    await flushPromises()

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })
})
