// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useApplicationStore } from '#shared/stores/application.ts'

import type { PageRoute } from '#desktop/components/PageNavigation/navigationItems.ts'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'

import dashboardRoutes from '../routes.ts'

const dashboardRoute = dashboardRoutes.find((route) => route.name === 'Dashboard')!

const dashboard: PageRoute = {
  path: dashboardRoute.path,
  name: dashboardRoute.name as string,
  meta: dashboardRoute.meta as PageRoute['meta'],
}

// The real dashboard route, and only that one, as the navigation's item list.
vi.mock('#desktop/components/PageNavigation/navigationItems.ts', () => ({
  get navigationItems() {
    return [{ type: 'route', order: 0, route: dashboard }]
  },
  numberOfPermanentItems: 0,
}))

const routerRoutes = [
  { path: '/', name: 'Root', component: { template: 'root' } },
  { path: '/dashboard', name: 'Dashboard', component: { template: 'dashboard' } },
]

const renderNavigation = (collapsed = false) =>
  renderComponent(PageNavigation, {
    router: true,
    routerRoutes,
    store: true,
    props: { collapsed },
  })

describe('dashboard navigation entry', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  // The collapsed state is persisted, so it would leak into the next example.
  afterEach(() => {
    localStorage.clear()
  })

  it('links to the dashboard', () => {
    mockApplicationConfig({ dashboard: true })

    const view = renderNavigation()

    expect(view.getByRole('link', { name: 'Dashboard' })).toHaveAttribute(
      'href',
      '/desktop/dashboard',
    )
  })

  it('shows an icon button in the collapsed sidebar', () => {
    mockApplicationConfig({ dashboard: true })

    const view = renderNavigation(true)

    expect(view.getByLabelText('Dashboard')).toBeInTheDocument()
  })

  it.each([false, true])(
    'is absent while the dashboard is turned off (collapsed: %s)',
    (collapsed) => {
      mockApplicationConfig({ dashboard: false })

      const view = renderNavigation(collapsed)

      expect(view.queryByRole('link', { name: 'Dashboard' })).not.toBeInTheDocument()
      expect(view.queryByLabelText('Dashboard')).not.toBeInTheDocument()
    },
  )

  it('disappears as soon as the dashboard is turned off', async () => {
    mockApplicationConfig({ dashboard: true })

    const view = renderNavigation()

    expect(view.getByRole('link', { name: 'Dashboard' })).toBeInTheDocument()

    useApplicationStore().config.dashboard = false
    await waitForNextTick()

    expect(view.queryByRole('link', { name: 'Dashboard' })).not.toBeInTheDocument()
  })
})
