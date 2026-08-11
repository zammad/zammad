// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import type {
  NavigationItem,
  PageRoute,
} from '#desktop/components/PageNavigation/navigationItems.ts'
import PageNavigation from '#desktop/components/PageNavigation/PageNavigation.vue'

const buildRoute = (name: string, title: string, icon: string, permission: string): PageRoute => ({
  path: `/${name}`,
  name,
  meta: {
    title,
    icon,
    requiredPermission: [permission],
    requiresAuth: true,
  },
})

const dashboard = buildRoute('dashboard', 'Dashboard', 'speedometer2', '*')
const timeTracking = buildRoute(
  'time-tracking',
  'Time tracking',
  'stopwatch',
  'time_tracking.agent',
)
const projectOverview = buildRoute('project-overview', 'Project overview', 'book', 'project_baller')

// Core ships no navigation groups, so the item list is mocked to cover the
//   grouping of routes contributed by (multiple) addons.
const defaultItems = (): NavigationItem[] => [
  { type: 'route', order: 0, route: dashboard },
  {
    type: 'group',
    order: 9000,
    group: { key: 'tools', title: 'Tools', icon: 'wrench', order: 9000 },
    routes: [timeTracking, projectOverview],
  },
]

let items = defaultItems()

vi.mock('#desktop/components/PageNavigation/navigationItems.ts', () => ({
  get navigationItems() {
    return items
  },
  numberOfPermanentItems: 0,
}))

// The fixture routes must be known to the router, otherwise `CommonLink` treats
//   them as external links and renders the raw path instead of resolving it.
const routerRoutes = [
  { path: '/', name: 'Root', component: { template: 'root' } },
  ...[dashboard, timeTracking, projectOverview].map(({ path, name }) => ({
    path,
    name,
    component: { template: name },
  })),
]

const renderPageNavigation = (collapsed = false) =>
  renderComponent(PageNavigation, { router: true, routerRoutes, store: true, props: { collapsed } })

describe('PageNavigation', () => {
  beforeEach(() => {
    items = defaultItems()
    mockPermissions(['*', 'time_tracking.agent', 'project_baller'])
  })

  it('renders ungrouped routes as links', () => {
    const view = renderPageNavigation()

    expect(view.getByRole('link', { name: 'Dashboard' })).toHaveAttribute(
      'href',
      '/desktop/dashboard',
    )
  })

  it('renders a group as a single entry instead of one entry per route', () => {
    const view = renderPageNavigation()

    expect(view.getByRole('button', { name: 'Tools' })).toBeInTheDocument()
    expect(view.queryByRole('link', { name: 'Time tracking' })).not.toBeInTheDocument()
    expect(view.queryByRole('link', { name: 'Project overview' })).not.toBeInTheDocument()
  })

  it('combines routes of independent contributors in one menu', async () => {
    const view = renderPageNavigation()

    await view.events.click(view.getByRole('button', { name: 'Tools' }))

    expect(view.getByRole('link', { name: 'Time tracking' })).toHaveAttribute(
      'href',
      '/desktop/time-tracking',
    )
    expect(view.getByRole('link', { name: 'Project overview' })).toHaveAttribute(
      'href',
      '/desktop/project-overview',
    )
  })

  it('closes the menu after a route was chosen', async () => {
    const view = renderPageNavigation()

    await view.events.click(view.getByRole('button', { name: 'Tools' }))
    await view.events.click(view.getByRole('link', { name: 'Time tracking' }))

    expect(view.queryByRole('link', { name: 'Time tracking' })).not.toBeInTheDocument()
  })

  it('connects the group entry with its menu for assistive technology', async () => {
    const view = renderPageNavigation()

    const trigger = view.getByRole('button', { name: 'Tools' })
    expect(trigger).toHaveAttribute('aria-expanded', 'false')

    await view.events.click(trigger)

    expect(trigger).toHaveAttribute('aria-expanded', 'true')

    const menu = document.getElementById(trigger.getAttribute('aria-controls') as string)
    expect(menu).toBeTruthy()
    expect(menu).toHaveAttribute('aria-labelledby', trigger.id)
  })

  it('hides routes of a group the user has no permission for', async () => {
    mockPermissions(['*', 'project_baller'])

    const view = renderPageNavigation()

    await view.events.click(view.getByRole('button', { name: 'Tools' }))

    expect(view.queryByRole('link', { name: 'Time tracking' })).not.toBeInTheDocument()
    expect(view.getByRole('link', { name: 'Project overview' })).toBeInTheDocument()
  })

  it('hides the group when none of its routes are permitted', () => {
    mockPermissions(['*'])

    const view = renderPageNavigation()

    expect(view.queryByRole('button', { name: 'Tools' })).not.toBeInTheDocument()
    expect(view.getByRole('link', { name: 'Dashboard' })).toBeInTheDocument()
  })

  it('respects the dynamic access gate of a route', () => {
    items = [
      {
        type: 'group',
        order: 9000,
        group: { key: 'tools', title: 'Tools', icon: 'wrench', order: 9000 },
        routes: [{ ...timeTracking, meta: { ...timeTracking.meta, canAccess: () => false } }],
      },
    ]

    const view = renderPageNavigation()

    expect(view.queryByRole('button', { name: 'Tools' })).not.toBeInTheDocument()
  })

  describe('collapsed sidebar', () => {
    it('closes an open menu when the sidebar collapses', async () => {
      const view = renderPageNavigation()

      await view.events.click(view.getByRole('button', { name: 'Tools' }))
      expect(view.getByRole('link', { name: 'Time tracking' })).toBeInTheDocument()

      await view.rerender({ collapsed: true })

      expect(view.queryByRole('link', { name: 'Time tracking' })).not.toBeInTheDocument()
    })

    it('keeps a group as one icon with a fly-out menu', async () => {
      const view = renderPageNavigation(true)

      expect(view.getByIconName('wrench')).toBeInTheDocument()
      expect(view.queryByIconName('stopwatch')).not.toBeInTheDocument()

      await view.events.click(view.getByLabelText('Tools'))

      expect(view.getByRole('link', { name: 'Time tracking' })).toBeInTheDocument()
      expect(view.getByRole('link', { name: 'Project overview' })).toBeInTheDocument()
    })
  })
})
