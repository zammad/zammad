// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import AdminMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AdminMenu/AdminMenu.vue'
import { COLLAPSED_STATE_KEY } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

describe('AdminMenu', () => {
  describe('create ticket action button', () => {
    it('renders setting button ', () => {
      mockPermissions(['admin.monitoring'])

      const wrapper = renderComponent(AdminMenu, {
        provide: [[COLLAPSED_STATE_KEY, computed(() => true)]],
        router: true,
      })

      expect(wrapper.getByLabelText('Administration')).toBeInTheDocument()
    })

    it('does not renders setting button if user has not permission', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderComponent(AdminMenu, {
        provide: [[COLLAPSED_STATE_KEY, computed(() => true)]],
        router: true,
      })

      expect(wrapper.queryByLabelText('Administration')).not.toBeInTheDocument()
    })
  })
})
