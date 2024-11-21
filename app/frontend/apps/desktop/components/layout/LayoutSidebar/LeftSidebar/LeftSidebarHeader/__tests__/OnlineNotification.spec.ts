// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { getOnlineNotificationsCountSubscriptionHandler } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.mocks.ts'

import OnlineNotification from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification.vue'

import '#tests/graphql/builders/mocks.ts'

describe('OnlineNotification', () => {
  it('displays notification logo without unseen notifications', async () => {
    const wrapper = renderComponent(OnlineNotification, {
      props: { collapsed: false },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    expect(
      wrapper.getByRole('button', { name: 'Show notifications' }),
    ).toBeInTheDocument()

    expect(wrapper.getByIconName('logo')).toBeInTheDocument()

    expect(
      wrapper.queryByRole('status', { name: 'Unseen notifications count' }),
    ).not.toBeInTheDocument()
  })

  it('displays unseen notifications count', async () => {
    const wrapper = renderComponent(OnlineNotification)

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 10,
      },
    })

    expect(
      wrapper.getByRole('status', { name: 'Unseen notifications count' }),
    ).toHaveTextContent('10')
  })
})
