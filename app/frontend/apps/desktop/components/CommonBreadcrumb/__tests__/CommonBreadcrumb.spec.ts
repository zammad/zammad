// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
      router: true,
    })

    const link = view.getByRole('link')

    expect(link).toHaveTextContent('Dashboard')
    expect(link).toHaveAttribute('href', '/desktop/')
    expect(view.getByText('Settings')).toBeInTheDocument()
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
})
