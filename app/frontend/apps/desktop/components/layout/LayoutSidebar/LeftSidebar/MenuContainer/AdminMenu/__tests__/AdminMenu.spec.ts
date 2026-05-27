// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import AdminMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AdminMenu/AdminMenu.vue'
import { isSidebarCollapsed, SidebarName } from '#desktop/components/layout/useSidebarDisplay.ts'

describe('AdminMenu', () => {
  beforeEach(() => {
    isSidebarCollapsed[SidebarName.Primary].value = true
  })

  describe('create ticket action button', () => {
    it('renders setting button', () => {
      mockPermissions(['admin.monitoring'])

      const wrapper = renderComponent(AdminMenu, {
        router: true,
      })

      expect(wrapper.getByLabelText('Administration')).toBeInTheDocument()
    })

    it('does not renders setting button if user has not permission', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderComponent(AdminMenu, {
        router: true,
      })

      expect(wrapper.queryByLabelText('Administration')).not.toBeInTheDocument()
    })
  })
})
