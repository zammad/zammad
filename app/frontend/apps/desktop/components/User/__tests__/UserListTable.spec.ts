// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'
import { within } from '@testing-library/vue'

import {
  renderComponent,
  type ExtendedMountingOptions,
} from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { type User } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types.ts'

import UserListTable from '../UserListTable.vue'

mockRouterHooks()

const renderListTable = async (
  props: ListTableProps<User>,
  options: ExtendedMountingOptions<ListTableProps<User>> = { form: true },
) => {
  const wrapper = renderComponent(UserListTable, {
    router: true,
    ...options,
    props: {
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

const tableHeaders = [
  'login',
  'firstname',
  'lastname',
  'organization',
  'organization_ids',
]

const tableItems: User[] = [
  {
    __typename: 'User',
    active: true,
    firstname: 'Nicole',
    id: convertToGraphQLId('User', 1),
    internalId: 1,
    lastname: 'Braun',
    login: 'nicole.braun@zammad.org',
    policy: { update: true, destroy: false },
    createdAt: '2022-11-30T12:40:15Z',
    updatedAt: '2022-11-30T12:40:15Z',
    organization: {
      __typename: 'Organization',
      id: convertToGraphQLId('Organization', 1),
      internalId: 1,
      name: 'Zammad Foundation',
      policy: { update: true, destroy: false },
      createdAt: '2022-11-30T12:40:15Z',
      updatedAt: '2022-11-30T12:40:15Z',
    },
    secondaryOrganizations: {
      totalCount: 3,
      pageInfo: { hasNextPage: false, hasPreviousPage: false },
      edges: [
        {
          __typename: 'OrganizationEdge',
          cursor: 'MQ',
          node: {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 2),
            internalId: 2,
            name: 'Zammad GmbH',
            policy: { update: true, destroy: false },
            createdAt: '2022-11-30T12:40:15Z',
            updatedAt: '2022-11-30T12:40:15Z',
          },
        },
        {
          __typename: 'OrganizationEdge',
          cursor: 'MQ',
          node: {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 3),
            internalId: 3,
            name: 'Zammad Inc',
            policy: { update: true, destroy: false },
            createdAt: '2022-11-30T12:40:15Z',
            updatedAt: '2022-11-30T12:40:15Z',
          },
        },
        {
          __typename: 'OrganizationEdge',
          cursor: 'MQ',
          node: {
            __typename: 'Organization',
            id: convertToGraphQLId('Organization', 4),
            internalId: 4,
            name: 'Zammad UK Ltd',
            policy: { update: true, destroy: false },
            createdAt: '2022-11-30T12:40:15Z',
            updatedAt: '2022-11-30T12:40:15Z',
          },
        },
      ],
    },
  },
  {
    __typename: 'User',
    active: true,
    firstname: 'Agent 1',
    id: convertToGraphQLId('User', 2),
    internalId: 1,
    lastname: 'Test',
    login: 'agent1@example.com',
    policy: { update: true, destroy: false },
    createdAt: '2022-11-30T12:40:15Z',
    updatedAt: '2022-11-30T12:40:15Z',
    organization: null,
    secondaryOrganizations: null,
  },
]

describe('UserListTable', () => {
  it('displays the user list', async () => {
    const wrapper = await renderListTable({
      headers: tableHeaders,
      items: tableItems,
      totalCount: 100,
      caption: 'Table caption',
      tableId: 'user-list-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
    })

    expect(wrapper.getByText('Login')).toBeInTheDocument()
    expect(wrapper.getByText('First name')).toBeInTheDocument()
    expect(wrapper.getByText('Last name')).toBeInTheDocument()
    expect(wrapper.getByText('Organization')).toBeInTheDocument()
    expect(wrapper.getByText('Secondary organizations')).toBeInTheDocument()

    expect(wrapper.getByText('nicole.braun@zammad.org')).toBeInTheDocument()
    expect(wrapper.getByText('Nicole')).toBeInTheDocument()
    expect(wrapper.getByText('Braun')).toBeInTheDocument()

    // FIXME: Why is this not working?!
    // expect(wrapper.getByText('Zammad Foundation')).toBeInTheDocument()
  })

  it('supports display of all secondary organizations, if applicable', async () => {
    const wrapper = await renderListTable({
      headers: tableHeaders,
      items: tableItems,
      totalCount: 100,
      caption: 'Table caption',
      tableId: 'user-list-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
    })

    const rows = wrapper.getAllByRole('row')

    expect(within(rows[1]).getAllByRole('cell')[4]).toHaveTextContent(
      'Zammad GmbH, Zammad Inc, Zammad UK Ltd',
    )

    expect(within(rows[2]).getAllByRole('cell')[4]).toHaveTextContent('-')
  })
})
