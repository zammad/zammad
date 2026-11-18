// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import FormUpdaterUser from '#tests/graphql/factories/types/FormUpdaterUser.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockAutocompleteSearchOrganizationQuery,
  waitForAutocompleteSearchOrganizationQueryCalls,
} from '#shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.mocks.ts'
import { FormUpdaterDocument } from '#shared/components/Form/graphql/queries/formUpdater.api.ts'
import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/core/attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { mockOrganizationQuery } from '#shared/entities/organization/graphql/queries/organization.mocks.ts'
import { waitForUserAddMutationCalls } from '#shared/entities/user/graphql/mutations/add.mocks.ts'
import {
  EnumFormUpdaterId,
  type FormUpdaterQuery,
  type Organization,
} from '#shared/graphql/types.ts'
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
  const header = within(main).getByTestId('organization-detail-top-bar-full-details')

  return { view, main, header }
}

const mockUserCreateAttributes = () =>
  mockObjectManagerFrontendAttributesQuery({
    objectManagerFrontendAttributes: {
      attributes: [],
      screens: [
        {
          name: 'create',
          attributes: [
            'firstname',
            'lastname',
            'email',
            'web',
            'phone',
            'mobile',
            'fax',
            'organization_id',
            'organization_ids',
            'address',
            'password',
            'vip',
            'note',
            'role_ids',
            'group_ids',
          ],
        },
      ],
    },
  })

describe('Organization Detail View - New User', () => {
  beforeEach(() => {
    mockOrganizationQuery({ organization })
  })

  it('creates new user for current organization', async () => {
    mockPermissions(['ticket.agent'])
    mockUserCreateAttributes()

    mockFormUpdaterQuery({
      formUpdater: FormUpdaterUser(),
    })

    const { view, header } = await visitOrganizationView()

    await view.events.click(within(header).getByRole('button', { name: 'New user' }))

    const flyout = await view.findByRole('complementary', { name: 'New user' })

    const firstname = await within(flyout).findByLabelText('First name')

    await view.events.type(firstname, 'User first name')

    expect(within(flyout).getByLabelText('Organization')).toHaveValue(organization.name)

    const createButton = within(flyout).getByRole('button', { name: 'Create' })

    await view.events.click(createButton)

    const calls = await waitForUserAddMutationCalls()

    expect(calls.at(-1)?.variables.input).toMatchObject({
      firstname: 'User first name',
      organizationId: organization.id,
    })
  })

  it('keeps a different picked organization after the form updater responds', async () => {
    mockPermissions(['ticket.agent'])
    mockUserCreateAttributes()

    mockFormUpdaterQuery({
      formUpdater: FormUpdaterUser(),
    })

    const { view, header } = await visitOrganizationView()

    await view.events.click(within(header).getByRole('button', { name: 'New user' }))

    const flyout = await view.findByRole('complementary', { name: 'New user' })
    const organizationField = await within(flyout).findByLabelText('Organization')

    expect(organizationField).toHaveValue(organization.name)

    mockAutocompleteSearchOrganizationQuery({
      autocompleteSearchOrganization: [
        {
          __typename: 'AutocompleteSearchOrganizationEntry',
          value: 2,
          label: 'Hooli',
          labelPlaceholder: [],
          heading: '',
          headingPlaceholder: [],
          disabled: false,
          icon: null,
          organization: {
            id: convertToGraphQLId('Organization', 2),
            internalId: 2,
            name: 'Hooli',
          },
        },
      ],
    })

    await view.events.click(organizationField)
    await view.events.type(within(organizationField).getByRole('searchbox'), 'Hooli')
    await waitForAutocompleteSearchOrganizationQueryCalls()

    await view.events.click(await view.findByRole('option', { name: /Hooli/ }))

    await waitFor(() => {
      const calls = getGraphQLMockCalls<FormUpdaterQuery>(FormUpdaterDocument)
      expect(
        calls.some(
          (call) =>
            call.variables.formUpdaterId === EnumFormUpdaterId.FormUpdaterUpdaterUserCreate &&
            call.variables.data?.organization_id === 2,
        ),
      ).toBe(true)
    })

    await flushPromises()
    await flushPromises()

    expect(organizationField).toHaveValue('Hooli')
  })
})
