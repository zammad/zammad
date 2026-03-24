// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockGraphQLApi, mockGraphQLSubscription } from '#tests/support/mock-graphql-api.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'
import { waitUntil, waitUntilApisResolved } from '#tests/support/utils.ts'

import { OrganizationDocument } from '#shared/entities/organization/graphql/queries/organization.api.ts'
import { OrganizationUpdatesDocument } from '#shared/entities/organization/graphql/subscriptions/organizationUpdates.api.ts'

import {
  defaultOrganization,
  mockOrganizationObjectAttributes,
} from '#mobile/entities/organization/__tests__/mocks/organization-mocks.ts'
import {
  defaultUser,
  mockUserDetailsApis,
} from '#mobile/entities/user/__tests__/mocks/user-mocks.ts'

import { mockTicketDetailViewGql } from './mocks/detail-view.ts'
import { mockTicketsByOverview } from './mocks/overview.ts'

describe('testing ticket a11y', () => {
  beforeEach(() => {
    mockTicketOverviews()
  })

  test('ticket overview has no accessibility violations', async () => {
    mockTicketsByOverview([])
    const view = await visitView('/tickets/view')

    expect(view.container).toBeAccessible()
  })

  test('ticket detail view has no accessibility violations', async () => {
    const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

    const view = await visitView('/tickets/1')

    expect(view.getByTestId('loader-list')).toBeInTheDocument()
    expect(view.getByTestId('loader-title')).toBeInTheDocument()
    expect(view.getByTestId('loader-header')).toBeInTheDocument()

    await waitUntilTicketLoaded()

    expect(view.container).toBeAccessible()
  })

  test('ticket organization information has no accessibility violations', async () => {
    mockTicketDetailViewGql()

    const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
      organization: defaultOrganization(),
    })
    mockGraphQLSubscription(OrganizationUpdatesDocument)
    const mockAttributes = mockOrganizationObjectAttributes()

    await visitView('/tickets/1/information/organization')

    await waitUntil(() => mockApi.calls.resolve && mockAttributes.calls.resolve)

    const view = await visitView('/tickets/1/information/organization')

    expect(view.container).toBeAccessible()
  })

  test('ticket user information has no accessibility violations', async () => {
    mockTicketDetailViewGql()

    const { mockUser, mockAttributes } = mockUserDetailsApis(defaultUser(), {
      skipMockOnlineNotificationSeen: true,
    })

    await visitView('/tickets/1/information/customer')

    await waitUntilApisResolved(mockUser, mockAttributes)

    const view = await visitView('/tickets/1/information/customer')

    expect(view.container).toBeAccessible()
  })
})
