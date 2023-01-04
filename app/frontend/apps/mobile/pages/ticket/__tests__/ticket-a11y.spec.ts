// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { visitView } from '@tests/support/components/visitView'
import { mockTicketOverviews } from '@tests/support/mocks/ticket-overviews'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { waitUntil, waitUntilApisResolved } from '@tests/support/utils'
import { OrganizationDocument } from '@mobile/entities/organization/graphql/queries/organization.api'
import { OrganizationUpdatesDocument } from '@mobile/entities/organization/graphql/subscriptions/organizationUpdates.api'
import {
  defaultOrganization,
  mockOrganizationObjectAttributes,
} from '@mobile/entities/organization/__tests__/mocks/organization-mocks'
import {
  defaultUser,
  mockUserDetailsApis,
} from '@mobile/entities/user/__tests__/mocks/user-mocks'
import { mockTicketsByOverview } from './mocks/overview'
import { mockTicketDetailViewGql } from './mocks/detail-view'

describe('testing ticket a11y', () => {
  beforeEach(() => {
    mockTicketOverviews()
  })

  test('ticket overview has no accessibility violations', async () => {
    mockTicketsByOverview([])
    await visitView('/tickets/view')

    const results = await axe(document.body)
    expect(results).toHaveNoViolations()
  })

  test('ticket detail view has no accessibility violations', async () => {
    const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

    const view = await visitView('/tickets/1')

    expect(view.getByTestId('loader-list')).toBeInTheDocument()
    expect(view.getByTestId('loader-title')).toBeInTheDocument()
    expect(view.getByTestId('loader-header')).toBeInTheDocument()

    await waitUntilTicketLoaded()

    const results = await axe(document.body)
    expect(results).toHaveNoViolations()
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

    const results = await axe(document.body)
    expect(results).toHaveNoViolations()
  })

  test('ticket user information has no accessibility violations', async () => {
    mockTicketDetailViewGql()

    const { mockUser, mockAttributes } = mockUserDetailsApis(defaultUser())

    await visitView('/tickets/1/information/customer')

    await waitUntilApisResolved(mockUser, mockAttributes)

    const results = await axe(document.body)
    expect(results).toHaveNoViolations()
  })
})
