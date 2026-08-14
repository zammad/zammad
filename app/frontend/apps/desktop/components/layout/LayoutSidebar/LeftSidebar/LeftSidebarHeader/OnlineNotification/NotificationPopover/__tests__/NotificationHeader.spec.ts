// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import NotificationHeader from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationHeader.vue'

describe('NotificationHeader', () => {
  it('displays notification header', () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: true,
        hasNotifications: true,
      },
    })

    expect(wrapper.getByRole('button', { name: 'mark all as read' })).toBeInTheDocument()
    expect(wrapper.getByRole('heading', { level: 3 })).toHaveTextContent('Notifications')
    expect(wrapper.getByIconName('lightning')).toBeInTheDocument()
  })

  it('hides mark all as read button if prop is set to false', () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: true,
      },
    })

    expect(wrapper.queryByRole('button', { name: 'mark all as read' })).not.toBeInTheDocument()
  })

  it('emits mark-all event', async () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: true,
        hasNotifications: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'mark all as read' }))

    expect(wrapper.emitted('mark-all')).toHaveLength(1)
  })

  it('displays clear all button when there are notifications', () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: true,
      },
    })

    expect(wrapper.getByRole('button', { name: 'Clear all' })).toBeInTheDocument()
    expect(wrapper.getByIconName('trash3')).toBeInTheDocument()
  })

  it('hides clear all button when there are no notifications', () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: false,
      },
    })

    expect(wrapper.queryByRole('button', { name: 'Clear all' })).not.toBeInTheDocument()
  })

  it('emits clear-all event', async () => {
    const wrapper = renderComponent(NotificationHeader, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Clear all' }))

    expect(wrapper.emitted('clear-all')).toHaveLength(1)
  })
})
