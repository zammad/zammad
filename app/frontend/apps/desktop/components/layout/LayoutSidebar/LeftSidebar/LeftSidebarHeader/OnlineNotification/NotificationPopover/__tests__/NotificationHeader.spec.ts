// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import NotificationHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationHeader.vue'

describe('NotificationHeader', () => {
  it('displays notification header', () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: true,
      },
    })

    expect(wrapper.getByRole('button')).toHaveTextContent('mark all as read')
    expect(wrapper.getByRole('heading', { level: 3 })).toHaveTextContent(
      'Notifications',
    )
    expect(wrapper.getByIconName('lightning')).toBeInTheDocument()
  })

  it('hides mark all as read button if prop is set to false', () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: false,
      },
    })

    expect(
      wrapper.queryByRole('button', { name: 'mark all as read' }),
    ).not.toBeInTheDocument()
  })

  it('emits mark-all event', async () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: true,
      },
    })

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'mark all as read' }),
    )

    expect(wrapper.emitted('mark-all')).toHaveLength(1)
  })
})
