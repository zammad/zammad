// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import LeftSidebarHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader.vue'

import '#tests/graphql/builders/mocks.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      readQuery: vi.fn(),
      writeQuery: vi.fn(),
    },
  }),
}))

const renderLeftSidebarHeader = (collapsed = true, noPermission?: boolean) => {
  if (noPermission) mockPermissions([])
  else mockPermissions(['ticket.agent'])

  const searchValue = ref('')
  const searchActive = ref(false)

  const wrapper = renderComponent(LeftSidebarHeader, {
    props: { collapsed },
    vModel: {
      search: searchValue,
      searchActive,
    },
    router: true,
  })

  return { wrapper, searchValue, searchActive }
}

describe('LeftSidebarHeader', () => {
  it('displays notification button if collapsed', async () => {
    const { wrapper } = renderLeftSidebarHeader()

    expect(wrapper.getByRole('button', { name: 'Show notifications' })).toBeInTheDocument()
  })

  it('displays notification button if not collapsed', async () => {
    const { wrapper } = renderLeftSidebarHeader(false)

    expect(wrapper.getByRole('button', { name: 'Show notifications' })).toBeInTheDocument()
  })

  it('hides Online Notification when search is active', async () => {
    const { wrapper } = renderLeftSidebarHeader(false)
    wrapper.getByRole('searchbox', { name: 'Search…' }).focus()
    await waitForNextTick()

    expect(wrapper.queryByRole('button', { name: 'Show notifications' })).not.toBeInTheDocument()
  })

  it('hides search field if collapsed is true', async () => {
    const { wrapper } = renderLeftSidebarHeader(true)

    expect(wrapper.queryByRole('searchbox', { name: 'Search…' })).not.toBeInTheDocument()
  })

  it('shows dummy logo when user has no agent permission (#5835)', async () => {
    const { wrapper } = renderLeftSidebarHeader(true, true)

    expect(wrapper.queryByRole('button', { name: 'Show notifications' })).not.toBeInTheDocument()
    expect(wrapper.getByIconName('logo')).toBeInTheDocument()
  })
})
