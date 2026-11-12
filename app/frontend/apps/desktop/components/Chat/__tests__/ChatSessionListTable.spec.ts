// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  EnumChatSessionState,
  EnumOrderDirection,
  type DetailSearchQuery,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { ListTableProps } from '#desktop/components/CommonTable/types.ts'

import ChatSessionListTable from '../ChatSessionListTable.vue'

type ChatSessionResult = Extract<
  DetailSearchQuery['search']['items'][number],
  { __typename: 'ChatSession' }
>

mockRouterHooks()

const routerRoutes = [
  { path: '/', name: 'Dashboard', component: { template: '<div />' } },
  { path: '/chat/session/:internalId', name: 'ChatSession', component: { template: '<div />' } },
]

// The shape the detailed search selects: `detailSearch.graphql` aliases the state.
const chatSession = (
  internalId: number,
  sessionState: EnumChatSessionState,
  name: string | null = null,
): ChatSessionResult => ({
  __typename: 'ChatSession',
  id: convertToGraphQLId('Chat::Session', internalId),
  internalId,
  name,
  sessionState,
  createdAt: '2026-11-03T11:00:00Z',
})

const renderListTable = async (props: Partial<ListTableProps<ChatSessionResult>> = {}) => {
  const wrapper = renderComponent(ChatSessionListTable, {
    router: true,
    routerRoutes,
    form: true,
    props: {
      headers: ['internal_id', 'name', 'state', 'created_at'],
      items: [
        chatSession(5, EnumChatSessionState.Closed, 'VPN setup'),
        chatSession(6, EnumChatSessionState.Running),
        chatSession(7, EnumChatSessionState.Waiting),
      ],
      totalCount: 3,
      caption: 'Search result for: Chat session',
      tableId: 'search-Chat__Session-table',
      maxItems: 1000,
      loading: false,
      loadingNewPage: false,
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

describe('ChatSessionListTable', () => {
  it('renders the number, the name, the state and the creation of each session', async () => {
    const wrapper = await renderListTable()

    expect(wrapper.getByRole('columnheader', { name: 'Number' })).toBeInTheDocument()
    expect(wrapper.getByRole('columnheader', { name: 'Name' })).toBeInTheDocument()
    expect(wrapper.getByRole('columnheader', { name: 'State' })).toBeInTheDocument()
    expect(wrapper.getByRole('columnheader', { name: 'Created at' })).toBeInTheDocument()

    expect(wrapper.getByText('VPN setup')).toBeInTheDocument()
    expect(wrapper.getByText('Closed')).toBeInTheDocument()
    expect(wrapper.getByText('Running')).toBeInTheDocument()
    expect(wrapper.getByText('Waiting')).toBeInTheDocument()
  })

  // The number is there for every session, the name only once an agent gave one.
  it('links the number of a session to its window in the chat page', async () => {
    const wrapper = await renderListTable()

    expect(wrapper.getByRole('link', { name: '5' })).toHaveAttribute(
      'href',
      '/desktop/chat/session/5',
    )
    expect(wrapper.getByRole('link', { name: '6' })).toHaveAttribute(
      'href',
      '/desktop/chat/session/6',
    )
  })

  // The search sorts by columns of the sessions table, which the internal id is not.
  it('sorts by the id for the number column, and by their own name for the others', async () => {
    const wrapper = await renderListTable()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Sort by Number ascending' }))
    await wrapper.events.click(wrapper.getByRole('button', { name: 'Sort by State ascending' }))

    expect(wrapper.emitted('sort')).toEqual([
      ['id', EnumOrderDirection.Ascending],
      ['state', EnumOrderDirection.Ascending],
    ])
  })

  it('marks the number column as sorted while the search is ordered by the id', async () => {
    const wrapper = await renderListTable({
      orderBy: 'id',
      orderDirection: EnumOrderDirection.Descending,
    })

    expect(wrapper.getByRole('columnheader', { name: 'Number' })).toHaveAttribute(
      'aria-sort',
      'descending',
    )
    expect(wrapper.getByRole('button', { name: 'Sort by Number ascending' })).toBeInTheDocument()
  })
})
