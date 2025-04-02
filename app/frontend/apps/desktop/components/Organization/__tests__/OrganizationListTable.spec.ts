// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import {
  renderComponent,
  type ExtendedMountingOptions,
} from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { type Organization } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types.ts'

import OrganizationListTable from '../OrganizationListTable.vue'

mockRouterHooks()

const renderListTable = async (
  props: ListTableProps<Organization>,
  options: ExtendedMountingOptions<ListTableProps<Organization>> = {
    form: true,
  },
) => {
  const wrapper = renderComponent(OrganizationListTable, {
    router: true,
    ...options,
    props: {
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

const tableHeaders = ['name', 'shared']

const tableItems: Organization[] = [
  {
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 1),
    internalId: 1,
    name: 'Zammad Foundation',
    shared: true,
    policy: { update: true, destroy: false },
    createdAt: '2022-11-30T12:40:15Z',
    updatedAt: '2022-11-30T12:40:15Z',
  },
]

describe('OrganizationListTable', () => {
  it('displays the organization list', async () => {
    const wrapper = await renderListTable({
      headers: tableHeaders,
      items: tableItems,
      totalCount: 100,
      caption: 'Table caption',
      tableId: 'organization-list-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
    })

    expect(wrapper.getByText('Name')).toBeInTheDocument()
    expect(wrapper.getByText('Shared organization')).toBeInTheDocument()

    expect(wrapper.getByText('Zammad Foundation')).toBeInTheDocument()
    expect(wrapper.getByText('yes')).toBeInTheDocument()
  })
})
