// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { OnlineNotificationsCountDocument } from '@shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api'
import { useSessionStore } from '@shared/stores/session'
import type { UserData } from '@shared/types/store'
import { renderComponent } from '@tests/support/components'
import { mockGraphQLSubscription } from '@tests/support/mock-graphql-api'
import { flushPromises } from '@vue/test-utils'
import LayoutBottomNavigation from '../LayoutBottomNavigation.vue'

describe('bottom navigation in layout', () => {
  it('renders navigation', async () => {
    mockGraphQLSubscription(OnlineNotificationsCountDocument)
    const view = renderComponent(LayoutBottomNavigation, {
      store: true,
      router: true,
    })
    const store = useSessionStore()

    store.user = {
      firstname: 'User',
      lastname: 'Test',
    } as UserData

    await flushPromises()

    expect(view.getByIconName('mobile-home')).toBeInTheDocument()
    expect(view.getByIconName('mobile-home').closest('a')).toHaveClass(
      'text-blue',
    )

    expect(
      view.getByIconName('mobile-notification-subscribed'),
    ).toBeInTheDocument()
    expect(view.getByText('UT')).toBeInTheDocument()
  })

  it('rendering notifications counter', async () => {
    const subscription = mockGraphQLSubscription(
      OnlineNotificationsCountDocument,
    )
    const view = renderComponent(LayoutBottomNavigation, {
      store: true,
      router: true,
    })
    const store = useSessionStore()

    store.user = {
      firstname: 'User',
      lastname: 'Test',
    } as UserData
    await flushPromises()

    expect(
      view.queryByRole('status', { name: 'Unread notifications' }),
    ).not.toBeInTheDocument()

    await subscription.next({
      data: {
        onlineNotificationsCount: {
          unseenCount: 1,
        },
      },
    })

    expect(
      view.getByRole('status', { name: 'Unread notifications' }),
    ).toHaveTextContent('1')
  })
})
