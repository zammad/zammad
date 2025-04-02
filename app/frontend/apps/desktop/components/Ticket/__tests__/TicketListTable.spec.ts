// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'
import {
  renderComponent,
  type ExtendedMountingOptions,
} from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { TicketByList } from '#shared/entities/ticket/types.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types.ts'

import TicketListTable from '../TicketListTable.vue'

mockRouterHooks()

const renderListTable = async (
  props: ListTableProps<TicketByList>,
  options: ExtendedMountingOptions<ListTableProps<TicketByList>> = {
    form: true,
  },
) => {
  const wrapper = renderComponent(TicketListTable, {
    router: true,
    ...options,
    props: {
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

const tableHeaders = ['title', 'owner', 'state', 'priority']

const tableItems: TicketByList[] = [
  {
    id: convertToGraphQLId('Ticket', 1),
    title: 'Dummy ticket',
    owner: {
      __typename: 'User',
      id: convertToGraphQLId('User', 1),
      fullname: 'Agent 1 Test',
    },
    state: {
      __typename: 'TicketState',
      id: convertToGraphQLId('TicketState', 1),
      name: 'open',
      stateType: {
        __typename: 'TicketStateType',
        id: convertToGraphQLId('TicketStateType', 1),
        name: 'open',
      },
    },
    priority: {
      __typename: 'TicketPriority',
      id: convertToGraphQLId('TicketPriority', 3),
      name: '3 high',
    },
    createdAt: '2021-01-01T12:00:00Z',
    internalId: 0,
    number: '',
    updatedAt: '',
    stateColorCode: EnumTicketStateColorCode.Closed,
    customer: {
      __typename: undefined,
      id: '',
      fullname: undefined,
    },
    group: {
      __typename: undefined,
      id: '',
      name: undefined,
    },
    policy: {
      __typename: undefined,
      update: false,
    },
  },
]

describe('TicketListTable', () => {
  it('displays the ticket list', async () => {
    const wrapper = await renderListTable({
      headers: tableHeaders,
      items: tableItems,
      totalCount: 100,
      caption: 'Table caption',
      tableId: 'ticket-list-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
    })

    expect(wrapper.getByText('Title')).toBeInTheDocument()
    expect(wrapper.getByText('Owner')).toBeInTheDocument()
    expect(wrapper.getByText('State')).toBeInTheDocument()

    expect(wrapper.getByText('Dummy ticket')).toBeInTheDocument()
    expect(wrapper.getByText('Agent 1 Test')).toBeInTheDocument()
    expect(wrapper.getByText('open')).toBeInTheDocument()
    expect(wrapper.getByText('3 high')).toBeInTheDocument()
  })
})
