// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import CommonSectionMenu from '../CommonSectionMenu.vue'
import type { MenuItem } from '../types'

describe('rendering section', () => {
  it('no output without default slot and items', () => {
    const view = renderComponent(CommonSectionMenu, {
      props: {
        headerLabel: 'Test Header',
      },
      router: true,
    })

    expect(view.queryByText('Test Header')).not.toBeInTheDocument()
  })

  it('if have header prop, renders header', () => {
    const view = renderComponent(CommonSectionMenu, {
      props: {
        headerLabel: 'Test Header',
        items: [
          {
            label: 'Example',
          },
        ],
      },
      router: true,
      store: true,
    })

    expect(view.getByText('Test Header')).toBeInTheDocument()
  })

  it('if have header slot, renders header', () => {
    const view = renderComponent(CommonSectionMenu, {
      slots: {
        header: '<div>Test Header</div>',
        default: 'Example',
      },
      router: true,
    })

    expect(view.getByText('Test Header')).toBeInTheDocument()
  })

  it('if have action prop, renders action and emits an event on click', async () => {
    const view = renderComponent(CommonSectionMenu, {
      props: {
        actionLabel: 'Edit',
      },
      slots: {
        default: 'Example',
      },
      router: true,
    })

    expect(view.getByText('Edit')).toBeInTheDocument()
    await view.events.click(view.getByText('Edit'))
    expect(view.emitted()['action-click']).toBeTruthy()
  })

  it('rendering items', () => {
    const items: MenuItem[] = [
      { type: 'link', link: '/login', label: 'Login' },
      { type: 'link', link: '/', label: 'Link' },
    ]

    const view = renderComponent(CommonSectionMenu, {
      shallow: false,
      props: {
        items,
      },
      router: true,
    })

    expect(view.getByText('Login')).toBeInTheDocument()
    expect(view.getByText('Link')).toBeInTheDocument()
  })

  it('rendering only items with permission', () => {
    const items: MenuItem[] = [
      { type: 'link', link: '/login', label: 'Login' },
      { type: 'link', link: '/', label: 'Link', permission: ['example'] },
    ]

    const view = renderComponent(CommonSectionMenu, {
      shallow: false,
      props: {
        items,
      },
      router: true,
    })

    expect(view.getByText('Login')).toBeInTheDocument()
    expect(view.queryByText('Link')).not.toBeInTheDocument()
  })
})
