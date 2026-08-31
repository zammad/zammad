// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import NotificationFooter from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationFooter.vue'

describe('NotificationFooter', () => {
  it('displays notification actions', () => {
    const wrapper = renderComponent(NotificationFooter, {
      props: {
        hasUnseenNotification: true,
        hasNotifications: true,
      },
    })

    expect(wrapper.getByRole('button', { name: 'mark all as read' })).toBeInTheDocument()
    expect(wrapper.getByIconName('lightning')).toBeInTheDocument()
  })

  it('hides mark all as read button if prop is set to false', () => {
    const wrapper = renderComponent(NotificationFooter, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: true,
      },
    })

    expect(wrapper.queryByRole('button', { name: 'mark all as read' })).not.toBeInTheDocument()
  })

  it('emits mark-all event', async () => {
    const wrapper = renderComponent(NotificationFooter, {
      props: {
        hasUnseenNotification: true,
        hasNotifications: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'mark all as read' }))

    expect(wrapper.emitted('mark-all')).toHaveLength(1)
  })

  it('displays clear all button when there are notifications', () => {
    const wrapper = renderComponent(NotificationFooter, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: true,
      },
    })

    expect(wrapper.getByRole('button', { name: 'clear all' })).toBeInTheDocument()
    expect(wrapper.getByIconName('trash3')).toBeInTheDocument()
  })

  it('hides clear all button when there are no notifications', () => {
    const wrapper = renderComponent(NotificationFooter, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: false,
      },
    })

    expect(wrapper.queryByRole('button', { name: 'clear all' })).not.toBeInTheDocument()
  })

  it('emits clear-all event', async () => {
    const wrapper = renderComponent(NotificationFooter, {
      props: {
        hasUnseenNotification: false,
        hasNotifications: true,
      },
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'clear all' }))

    expect(wrapper.emitted('clear-all')).toHaveLength(1)
  })
})
