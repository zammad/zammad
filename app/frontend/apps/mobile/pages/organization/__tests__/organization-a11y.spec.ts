// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { visitView } from '@tests/support/components/visitView'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { mockPermissions } from '@tests/support/mock-permissions'
import { waitUntil } from '@tests/support/utils'
import { OrganizationDocument } from '@mobile/entities/organization/graphql/queries/organization.api'
import { OrganizationUpdatesDocument } from '@mobile/entities/organization/graphql/subscriptions/organizationUpdates.api'
import {
  defaultOrganization,
  mockOrganizationObjectAttributes,
} from '@mobile/entities/organization/__tests__/mocks/organization-mocks'

describe('testing organization a11y', () => {
  it('has no accessibility violations', async () => {
    mockPermissions(['admin.organization'])

    const organization = defaultOrganization()
    const mockApi = mockGraphQLApi(OrganizationDocument).willResolve({
      organization,
    })
    mockGraphQLSubscription(OrganizationUpdatesDocument)
    mockOrganizationObjectAttributes()

    const view = await visitView(`/organizations/${organization.internalId}`)

    await waitUntil(() => mockApi.calls.resolve)

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
