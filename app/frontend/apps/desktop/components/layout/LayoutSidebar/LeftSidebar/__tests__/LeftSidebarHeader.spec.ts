// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import LeftSidebarHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader.vue'

import '#tests/graphql/builders/mocks.ts'

describe('LeftSidebarHeader', () => {
  it('displays notification button if collapsed', async () => {
    const wrapper = renderComponent(LeftSidebarHeader, {
      props: { collapsed: true },
    })

    expect(
      wrapper.getByRole('button', { name: 'Show notifications' }),
    ).toBeInTheDocument()
  })

  it('displays notification button if not collapsed', async () => {
    const wrapper = renderComponent(LeftSidebarHeader, {
      props: { collapsed: false },
    })

    expect(
      wrapper.getByRole('button', { name: 'Show notifications' }),
    ).toBeInTheDocument()
  })
})
