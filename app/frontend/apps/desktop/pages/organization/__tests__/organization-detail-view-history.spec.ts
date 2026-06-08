// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockOrganizationQuery } from '#shared/entities/organization/graphql/queries/organization.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockOrganizationHistoryQuery } from '#desktop/entities/organization/graphql/queries/history.mocks.ts'
import { mockUserHistoryQuery } from '#desktop/entities/user/graphql/queries/history.mocks.ts'

const organization = {
  id: 'gid://zammad/Organization/2',
  internalId: 2,
  name: 'Apple',
  shared: true,
  domain: '',
  domainAssignment: false,
  active: true,
  note: '',
  vip: false,
  objectAttributeValues: [
    {
      attribute: {
        name: 'multi_tree_organization',
        display: 'multi_tree_organization',
      },
      value: null,
      renderedLink: null,
    },
  ],
  allMembers: {
    edges: [
      {
        node: {
          id: 'gid://zammad/User/2',
          internalId: 2,
          image: null,
          firstname: 'Nicole',
          lastname: 'Braunn',
          fullname: 'Nicole Braunn',
          email: 'nicole.braun@zammad.org',
          phone: '22',
          outOfOffice: false,
          outOfOfficeStartAt: null,
          outOfOfficeEndAt: null,
          active: true,
          vip: false,
        },
      },
    ],
    pageInfo: {
      endCursor: 'MQ',
    },
    totalCount: 1,
  },
  policy: {
    update: true,
  },
  ticketsCount: {
    open: 1,
    closed: 0,
    openSearchQuery:
      'organization_id:2 AND state.name:("new" OR "open" OR "pending reminder" OR "pending close")',
    closedSearchQuery: 'organization_id:2 AND state.name:"closed"',
  },
}

describe('Organization Detail View - History Flyout', () => {
  beforeEach(() => {
    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
    })

    mockOrganizationQuery({ organization })
  })

  const assertFlyoutOpening = async () => {
    mockUserHistoryQuery({ userHistory: [] })

    const view = await visitView(`/organizations/${organization.internalId}`)

    const main = view.getByRole('main')
    const header = within(main).getByTestId('organization-detail-top-bar')

    await view.events.click(within(header).getByRole('button', { name: 'Action menu button' }))

    const actionPopover = await view.findByRole('region', { name: 'Action menu button' })
    await view.events.click(within(actionPopover).getByRole('button', { name: 'History' }))

    expect(await view.findByRole('heading', { name: 'History', level: 2 })).toBeVisible()
  }

  describe('With ticket.agent permission', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent'])
    })

    it('opens the History flyout from the action menu', assertFlyoutOpening)

    it('renders user history entries inside the flyout', async () => {
      mockOrganizationHistoryQuery({
        organizationHistory: [
          {
            createdAt: '2025-11-24T08:32:57Z',
            records: [
              {
                issuer: {
                  id: convertToGraphQLId('User', 3),
                  internalId: 3,
                  firstname: 'Test Admin',
                  lastname: 'Agent',
                  fullname: 'Test Admin Agent',
                  phone: '',
                  email: 'admin@example.com',
                  image: null,
                },
                events: [
                  {
                    createdAt: '2025-11-24T08:32:57Z',
                    action: 'created',
                    object: {
                      klass: 'Organization',
                      info: null,
                    },
                    attribute: null,
                    changes: {
                      from: null,
                      to: null,
                    },
                  },
                ],
              },
            ],
          },
        ],
      })

      const view = await visitView('/organizations/2')

      const main = view.getByRole('main')
      const header = within(main).getByTestId('organization-detail-top-bar')

      await view.events.click(within(header).getByRole('button', { name: 'Action menu button' }))
      const actionPopover = await view.findByRole('region', { name: 'Action menu button' })
      await view.events.click(within(actionPopover).getByRole('button', { name: 'History' }))

      const flyout = await view.findByRole('complementary', { name: 'History' })

      waitFor(() => {
        expect(within(flyout).getByText('Test Admin Agent')).toBeVisible()
        expect(within(flyout).getByText('2025-11-24 08:32')).toBeVisible()
      })
    })
  })

  describe('With admin.organization permission', () => {
    beforeEach(() => {
      mockPermissions(['admin.organization'])
    })

    it('opens the History flyout from the action menu', assertFlyoutOpening)
  })
})
