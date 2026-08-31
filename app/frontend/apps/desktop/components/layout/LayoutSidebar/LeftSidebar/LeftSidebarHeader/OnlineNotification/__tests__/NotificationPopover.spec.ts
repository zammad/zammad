// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import NotificationPopover from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover.vue'

const renderNotificationPopover = (props = {}) =>
  renderComponent(NotificationPopover, {
    props: {
      notificationList: [],
      loading: false,
      hasUnseenNotification: false,
      ...props,
    },
  })

describe('NotificationPopover', () => {
  it('labels the notification list with a heading', () => {
    const wrapper = renderNotificationPopover()

    expect(wrapper.getByRole('heading', { level: 3 })).toHaveTextContent('Notifications')
  })

  it('hides the action footer when there is nothing to act on', () => {
    const wrapper = renderNotificationPopover()

    expect(wrapper.getByText('No unread notifications.')).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'clear all' })).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'mark all as read' })).not.toBeInTheDocument()
    expect(wrapper.container.querySelector('footer')).toBeNull()
  })
})
