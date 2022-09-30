// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { OnlineNotificationsCountDocument } from '@shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api'
import { useSessionStore } from '@shared/stores/session'
import type { UserData } from '@shared/types/store'
import { renderComponent } from '@tests/support/components'
import { mockGraphQLSubscription } from '@tests/support/mock-graphql-api'
import { flushPromises } from '@vue/test-utils'
import LayoutBottomNavigation from '../LayoutBottomNavigation.vue'

// TODO: Add correct notification count test case, when real count output exists.
mockGraphQLSubscription(OnlineNotificationsCountDocument)

describe('bottom navigation in layout', () => {
  it('renders navigation', async () => {
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

    expect(view.getByIconName('home')).toBeInTheDocument()
    expect(view.getByIconName('home').closest('a')).toHaveClass('text-blue')

    expect(view.getByIconName('bell')).toBeInTheDocument()
    expect(view.getByText('UT')).toBeInTheDocument()
  })
})
