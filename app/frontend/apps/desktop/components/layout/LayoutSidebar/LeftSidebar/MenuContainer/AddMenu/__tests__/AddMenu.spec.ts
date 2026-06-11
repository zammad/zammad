// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { initializeStore } from '#tests/support/components/initializeStore.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import AddMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AddMenu/AddMenu.vue'
import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'

describe('AddMenu', () => {
  beforeEach(() => {
    initializeStore()
    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, true)
  })

  describe('create ticket action button', () => {
    it('renders action button', () => {
      mockPermissions(['ticket.agent', 'ticket.customer'])
      mockApplicationConfig({ customer_ticket_create: true })

      const wrapper = renderComponent(AddMenu, {
        router: true,
      })

      expect(wrapper.getByLabelText('New ticket')).toBeInTheDocument()
    })

    it('does not renders action button if user has not permission', () => {
      mockPermissions(['ticket.customer'])
      mockApplicationConfig({ customer_ticket_create: false })

      const wrapper = renderComponent(AddMenu, {
        router: true,
      })

      expect(wrapper.queryByLabelText('New ticket')).not.toBeInTheDocument()
    })
  })
})
