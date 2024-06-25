// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { mockOnlineNotificationSeenGql } from '#shared/composables/__tests__/mocks/online-notification.ts'
import { OrganizationDocument } from '#shared/entities/organization/graphql/queries/organization.api.ts'
import { OrganizationUpdatesDocument } from '#shared/entities/organization/graphql/subscriptions/organizationUpdates.api.ts'

import {
  defaultOrganization,
  mockOrganizationObjectAttributes,
} from '#mobile/entities/organization/__tests__/mocks/organization-mocks.ts'

describe('testing organization a11y', () => {
  it('has no accessibility violations', async () => {
    mockPermissions(['admin.organization'])
    mockOnlineNotificationSeenGql()

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
