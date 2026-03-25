// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import ticketCustomerObjectAttributes from '#tests/graphql/factories/fixtures/ticket-customer-object-attributes.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'

import {
  mockDefaultOverviewQueries,
  mockDefaultTicketsCachedByOverview,
} from './mocks/ticket-overviews-mocks.ts'

describe('ticket overviews view', () => {
  it('has no accessibility violations in main content', async () => {
    mockPermissions(['ticket.agent'])

    mockDefaultOverviewQueries()

    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: ticketCustomerObjectAttributes(),
    })

    mockDefaultTicketsCachedByOverview()

    const view = await visitView('/tickets/my_assigned')

    await flushPromises()

    await expect(view.container).toBeAccessible()
  })
})
