// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '@shared/stores/session'
import type { UserData } from '@shared/types/store'
import { renderComponent } from '@tests/support/components'
import { flushPromises } from '@vue/test-utils'
import LayoutBottomNavigation from '../LayoutBottomNavigation.vue'

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
