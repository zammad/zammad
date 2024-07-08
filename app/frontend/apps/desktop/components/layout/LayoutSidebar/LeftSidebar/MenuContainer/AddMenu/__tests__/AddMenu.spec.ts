// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, provide } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import AddMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/AddMenu/AddMenu.vue'
import { COLLAPSED_STATE_KEY } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

const renderAddMenu = () =>
  renderComponent(
    {
      template: `<AddMenu/>`,
      components: { AddMenu },
      setup() {
        provide(
          COLLAPSED_STATE_KEY,
          computed(() => true),
        )
      },
    },
    { router: true },
  )

describe('AddMenu', () => {
  describe('create ticket action button', () => {
    it('renders action button ', () => {
      mockPermissions(['ticket.agent', 'ticket.customer'])
      mockApplicationConfig({ customer_ticket_create: true })

      const wrapper = renderAddMenu()
      expect(wrapper.getByLabelText('New ticket')).toBeInTheDocument()
    })

    it('does not renders action button if user has not permission', () => {
      mockPermissions(['ticket.customer'])
      mockApplicationConfig({ customer_ticket_create: false })

      const wrapper = renderAddMenu()

      expect(wrapper.queryByLabelText('New ticket')).not.toBeInTheDocument()
    })
  })
})
