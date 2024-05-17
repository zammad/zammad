// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockGraphQLSubscription } from '#tests/support/mock-graphql-api.ts'

import { OnlineNotificationsCountDocument } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'

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
      id: convertToGraphQLId('User', 100),
      firstname: 'User',
      lastname: 'Test',
    } as UserData

    await flushPromises()

    expect(view.getByIconName('home')).toBeInTheDocument()
    expect(view.getByIconName('home').closest('a')).toHaveClass('text-blue')

    expect(view.getByIconName('notification-subscribed')).toBeInTheDocument()
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
      id: convertToGraphQLId('User', 100),
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
