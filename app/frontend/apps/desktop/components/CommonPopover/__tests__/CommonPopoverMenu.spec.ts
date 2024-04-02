// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import CommonPopoverMenu from '../CommonPopoverMenu.vue'
import type { MenuItem } from '../types.ts'

describe('rendering section', () => {
  it('no output without default slot and items', () => {
    const view = renderComponent(CommonPopoverMenu, {
      props: {
        headerLabel: 'Test Header',
      },
      router: true,
    })

    expect(view.queryByText('Test Header')).not.toBeInTheDocument()
  })

  it('if have header prop, renders header', () => {
    const view = renderComponent(CommonPopoverMenu, {
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
    const view = renderComponent(CommonPopoverMenu, {
      slots: {
        header: '<div>Test Header</div>',
        default: 'Example',
      },
      router: true,
    })

    expect(view.getByText('Test Header')).toBeInTheDocument()
  })

  it('rendering items', () => {
    const items: MenuItem[] = [
      { key: 'login', link: '/login', label: 'Login' },
      { key: 'dashboard', link: '/', label: 'Link' },
    ]

    const view = renderComponent(CommonPopoverMenu, {
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
      { key: 'login', link: '/login', label: 'Login' },
      { key: 'dashboard', link: '/', label: 'Link', permission: ['example'] },
    ]

    const view = renderComponent(CommonPopoverMenu, {
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
