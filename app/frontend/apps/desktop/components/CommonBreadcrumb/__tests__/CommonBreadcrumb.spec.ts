// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonBreadcrumb from '../CommonBreadcrumb.vue'

describe('breadcrumb', () => {
  it('renders the breadcrumb', async () => {
    const view = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
          },
          {
            label: 'Settings',
          },
        ],
      },
      slots: {
        trailing: 'trailing slot',
      },
      router: true,
    })

    const link = view.getByRole('link')

    expect(link).toHaveTextContent('Dashboard')
    expect(link).toHaveAttribute('href', '/desktop/')
    expect(view.getByText('Settings')).toBeInTheDocument()
    expect(view.getByText('trailing slot')).toBeInTheDocument()
  })

  it('renders icons', async () => {
    const view = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
            icon: 'eye',
          },
          {
            label: 'Settings',
          },
        ],
      },
      router: true,
    })

    const icon = view.getByIconName('eye')

    expect(icon).toBeInTheDocument()
  })

  it('emphasizes the last item', async () => {
    const view = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
          },
          {
            label: 'Settings',
          },
        ],
        emphasizeLastItem: true,
      },
      router: true,
    })

    const lastItem = view.getByText('Settings')

    expect(lastItem.parentElement).toHaveClass(
      'last:dark:text-white last:text-black',
    )
  })

  it('supports different text sizes', async () => {
    const view = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
          },
          {
            label: 'Settings',
          },
        ],
      },
      router: true,
    })

    // Default size
    expect(view.getByLabelText('Breadcrumb navigation')).toHaveClass(
      'text-base',
    )

    await view.rerender({
      items: [
        {
          label: 'Dashboard',
          route: '/',
        },
        {
          label: 'Settings',
        },
      ],
      size: 'small',
    })

    expect(view.getByLabelText('Breadcrumb navigation')).toHaveClass('text-xs')
  })

  it('support trailing slot', async () => {
    const view = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
          },
          {
            label: 'Settings',
          },
        ],
      },
      slots: {
        trailing: 'trailing slot',
      },
      router: true,
    })

    expect(view.getByText('trailing slot')).toBeInTheDocument()
  })

  it('supports setting an item to isActive', () => {
    const view = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
          },
          {
            label: 'Settings',
            isActive: true,
          },
        ],
      },
      slots: {
        trailing: 'trailing slot',
      },
      router: true,
    })

    expect(
      view.getByRole('heading', { name: 'Settings', level: 1 }),
    ).toHaveClass('text-black dark:text-white')
  })
})
