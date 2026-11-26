// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h, nextTick, ref, shallowRef } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { provideTicketSidebarContainer } from '#desktop/pages/ticket/composables/useTicketSidebarContainer.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

const selected = ref(false)
const content = ref('Sidebar content')

// Stands for a ticket view in the keep-alive cache: its sidebar container is not in the document.
const backgroundContainer = document.createElement('div')

const BackgroundTicketSidebar = defineComponent({
  setup: () => {
    provideTicketSidebarContainer(shallowRef(backgroundContainer))

    return () =>
      h(
        TicketSidebarWrapper,
        {
          sidebar: 'example',
          sidebarPlugin: {
            title: 'Example',
            icon: 'info-circle',
            order: 1,
            component: {},
            permissions: [],
            screens: [TicketSidebarScreenType.TicketDetailView],
            views: [],
          },
          selected: selected.value,
        },
        () => h('p', content.value),
      )
  },
})

describe('TicketSidebarWrapper', () => {
  it('renders into the sidebar of its own ticket view while that view is in the background', async () => {
    const activeContainer = document.createElement('div')
    activeContainer.id = 'ticketSidebar'
    document.body.appendChild(activeContainer)

    renderComponent(BackgroundTicketSidebar)

    selected.value = true
    await nextTick()

    content.value = 'Updated sidebar content'
    await nextTick()

    expect(backgroundContainer).toHaveTextContent('Updated sidebar content')
    expect(activeContainer).toBeEmptyDOMElement()

    activeContainer.remove()
  })
})
