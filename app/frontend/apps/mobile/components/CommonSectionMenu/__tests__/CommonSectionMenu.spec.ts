// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonSectionMenu from '../CommonSectionMenu.vue'
import type { MenuItem } from '../types'

describe('rendering section', () => {
  it('if have header prop, renders header', () => {
    const view = renderComponent(CommonSectionMenu, {
      props: {
        headerTitle: 'Test Header',
      },
      router: true,
      store: true,
    })

    expect(view.getByText('Test Header')).not.toBeNull()
  })

  it('if have header slot, renders header', () => {
    const view = renderComponent(CommonSectionMenu, {
      slots: {
        header: '<div>Test Header</div>',
      },
      router: true,
    })

    expect(view.getByText('Test Header')).not.toBeNull()
  })

  it('if have action prop, renders action and emits an event on click', async () => {
    const view = renderComponent(CommonSectionMenu, {
      props: {
        actionTitle: 'Edit',
      },
      router: true,
    })

    expect(view.getByText('Edit')).not.toBeNull()
    await view.events.click(view.getByText('Edit'))
    expect(view.emitted()['action-click']).toBeTruthy()
  })

  it('rendering iems', () => {
    const items: MenuItem[] = [
      { type: 'link', link: '/login', title: 'Login' },
      { type: 'link', link: '/', title: 'Link' },
    ]

    const view = renderComponent(CommonSectionMenu, {
      shallow: false,
      props: {
        items,
      },
      router: true,
    })

    expect(view.getByText('Login')).not.toBeNull()
    expect(view.getByText('Link')).not.toBeNull()
  })
})
