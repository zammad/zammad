// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonBreadcrumb from '../CommonBreadcrumb.vue'

describe('breadcrumb', () => {
  it('renders the breadcrumb', async () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
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

    const link = wrapper.getByRole('link', { name: 'Dashboard' })

    expect(link).toHaveTextContent('Dashboard')
    expect(link).toHaveAttribute('href', '/desktop/')
    expect(link).not.toHaveAttribute('aria-label')
    expect(wrapper.getByText('Settings')).toBeInTheDocument()
    expect(wrapper.getByText('trailing slot')).toBeInTheDocument()
  })

  it('renders icons', async () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
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

    const icon = wrapper.getByIconName('eye')

    expect(icon).toBeInTheDocument()
  })

  it('emphasizes the last item', async () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
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

    const lastItem = wrapper.getByText('Settings')

    expect(lastItem.parentElement).toHaveClass('last:dark:text-white last:text-black')
  })

  it('supports different text sizes', async () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
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
    expect(wrapper.getByLabelText('Breadcrumb navigation')).toHaveClass('text-base')

    await wrapper.rerender({
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

    expect(wrapper.getByLabelText('Breadcrumb navigation')).toHaveClass('text-xs')
  })

  it('support trailing slot', async () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
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

    expect(wrapper.getByText('trailing slot')).toBeInTheDocument()
  })

  it('supports setting an item to isActive', () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
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

    expect(wrapper.getByRole('heading', { name: 'Settings', level: 1 })).toHaveClass(
      'text-black dark:text-white',
    )
  })

  it('supports icon only display', () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
            icon: 'eye',
            iconOnly: true,
          },
          {
            label: 'Settings',
          },
        ],
      },
      router: true,
    })

    const icon = wrapper.getByIconName('eye')

    expect(icon).toBeInTheDocument()
    expect(wrapper.getByRole('link')).toHaveAttribute('aria-label', 'Dashboard')
    expect(wrapper.queryByText('Dashboard')).not.toBeInTheDocument()
  })

  it('support passing custom class to the icon', () => {
    const wrapper = renderComponent(CommonBreadcrumb, {
      props: {
        items: [
          {
            label: 'Dashboard',
            route: '/',
            icon: 'eye',
            iconClass: 'text-red-500',
          },
          {
            label: 'Settings',
          },
        ],
      },
      router: true,
    })

    const icon = wrapper.getByIconName('eye')

    expect(icon).toBeInTheDocument()
    expect(icon).toHaveClass('text-red-500')
  })
})
