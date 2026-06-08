// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import FormUpdaterOrganization from '#tests/graphql/factories/types/FormUpdaterOrganization.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { waitForOrganizationUpdateMutationCalls } from '#shared/entities/organization/graphql/mutations/update.mocks.ts'
import { mockOrganizationQuery } from '#shared/entities/organization/graphql/queries/organization.mocks.ts'
import type { Organization } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

const organization: Organization = {
  id: convertToGraphQLId('Organization', 1),
  internalId: 1,
  name: 'Zammad Foundation',
  shared: true,
  domain: '',
  domainAssignment: false,
  active: true,
  note: '<p dir="auto">note test</p><p dir="auto"></p>',
  vip: false,
  objectAttributeValues: [],
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
  createdBy: null,
  updatedBy: null,
  __typename: 'Organization',
  allMembers: {
    edges: [],
    pageInfo: {
      endCursor: 'MQ',
      hasNextPage: false,
      hasPreviousPage: false,
      __typename: 'PageInfo',
    },
    totalCount: 0,
    __typename: 'UserConnection',
  },
  policy: {
    update: true,
    destroy: true,
    __typename: 'PolicyDefault',
  },
  ticketsCount: {
    open: 11,
    closed: 6,
    openSearchQuery: 'openSearchQuery',
    closedSearchQuery: 'closedSearchQuery',
    __typename: 'TicketCount',
  },
}

const visitOrganizationView = async () => {
  const view = await visitView(`/organizations/${organization.internalId}`)

  const main = view.getByRole('main')
  const header = within(main).getByTestId('organization-detail-top-bar')

  return { view, main, header }
}

describe('Organization Detail View - Edit Organization', () => {
  beforeEach(() => {
    mockOrganizationQuery({ organization })
  })

  it('updates organization details', async () => {
    mockPermissions(['ticket.agent'])

    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: {
        attributes: [],
        screens: [
          {
            name: 'edit',
            attributes: [
              'name',
              'shared',
              'domain_assignment',
              'domain',
              'note',
              'active',
              'test',
              'textarea',
            ],
          },
        ],
      },
    })

    mockFormUpdaterQuery({
      formUpdater: FormUpdaterOrganization(),
    })

    const { view } = await visitOrganizationView()

    await view.events.click(view.getByRole('button', { name: 'Action menu button' }))

    const popover = await view.findByRole('region', { name: 'Action menu button' })

    await view.events.click(within(popover).getByRole('button', { name: 'Edit' }))

    const flyout = await view.findByRole('complementary', { name: 'Edit organization' })

    const name = await within(flyout).findByLabelText('Name')

    await view.events.clear(name)
    await view.events.type(name, 'Updated organization name')

    const updateButton = within(flyout).getByRole('button', { name: 'Update' })

    await view.events.click(updateButton)

    const calls = await waitForOrganizationUpdateMutationCalls()

    expect(calls.at(-1)?.variables.input).toMatchObject({
      name: 'Updated organization name',
    })
  })
})
