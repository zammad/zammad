// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { initializeStore } from '#tests/support/components/initializeStore.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import AdminMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AdminMenu/AdminMenu.vue'
import { useSidebarDisplayStore } from '#desktop/components/layout/stores/sidebarDisplay.ts'
import { SidebarName } from '#desktop/components/layout/types.ts'

describe('AdminMenu', () => {
  beforeEach(() => {
    initializeStore()
    useSidebarDisplayStore().setCollapsed(SidebarName.Primary, true)
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
