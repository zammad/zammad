// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import LeftSidebarHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader.vue'

import '#tests/graphql/builders/mocks.ts'

const renderLeftSidebarHeader = (collapsed = true) => {
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

    expect(
      wrapper.getByRole('button', { name: 'Show notifications' }),
    ).toBeInTheDocument()
  })

  it('displays notification button if not collapsed', async () => {
    const { wrapper } = renderLeftSidebarHeader(false)

    expect(
      wrapper.getByRole('button', { name: 'Show notifications' }),
    ).toBeInTheDocument()
  })

  it('hides Online Notification when search is active', async () => {
    const { wrapper } = renderLeftSidebarHeader(false)
    wrapper.getByRole('searchbox', { name: 'Search…' }).focus()
    await waitForNextTick()

    expect(
      wrapper.queryByRole('button', { name: 'Show notifications' }),
    ).not.toBeInTheDocument()
  })

  it('hides search field if collapsed is true', async () => {
    const { wrapper } = renderLeftSidebarHeader(true)

    expect(
      wrapper.queryByRole('searchbox', { name: 'Search…' }),
    ).not.toBeInTheDocument()
  })
})
