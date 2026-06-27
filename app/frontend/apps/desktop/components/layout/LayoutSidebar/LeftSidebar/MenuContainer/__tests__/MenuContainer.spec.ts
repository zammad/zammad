// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { expect } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import MenuContainer from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/MenuContainer.vue'
import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'

describe('ActionMenu', () => {
  it('renders container with two action menus', () => {
    mockPermissions(['ticket.agent', 'ticket.customer', 'admin'])
    mockApplicationConfig({ customer_ticket_create: true })
    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, false)

    const wrapper = renderComponent(MenuContainer, {
      router: true,
    })

    expect(wrapper.getAllByRole('listitem')).toHaveLength(2)

    expect(wrapper.getByLabelText('Administration')).toBeInTheDocument()

    expect(wrapper.getByLabelText('New ticket')).toBeInTheDocument()
  })

  it('changes orientation if collapsed is true', () => {
    mockPermissions(['ticket.agent', 'ticket.customer', 'admin'])
    mockApplicationConfig({ customer_ticket_create: true })
    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, true)

    const wrapper = renderComponent(MenuContainer, {
      router: true,
    })

    expect(wrapper.getByRole('list')).toHaveClass('flex-col')
  })
})
