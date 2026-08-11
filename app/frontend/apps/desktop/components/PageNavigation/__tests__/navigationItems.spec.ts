// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  navigationGroups,
  type NavigationGroup,
} from '#desktop/components/PageNavigation/navigationGroups.ts'
import {
  buildNavigationItems,
  type PageRoute,
} from '#desktop/components/PageNavigation/navigationItems.ts'

const buildRoute = (name: string, order?: number, navigationGroup?: string): PageRoute => ({
  path: `/${name}`,
  name,
  meta: {
    title: name,
    icon: 'book',
    requiredPermission: ['*'],
    requiresAuth: true,
    order,
    navigationGroup,
  },
})

const tools: NavigationGroup = { key: 'tools', title: 'Tools', icon: 'wrench', order: 9000 }

describe('navigationGroups', () => {
  it('ships the shared "tools" group so addons do not have to define it', () => {
    expect(navigationGroups).toContainEqual(
      expect.objectContaining({ key: 'tools', title: 'Tools' }),
    )
  })
})

describe('buildNavigationItems', () => {
  it('combines routes of independent contributors into one group', () => {
    const items = buildNavigationItems(
      [buildRoute('time-tracking', 9600, 'tools'), buildRoute('project-overview', 9650, 'tools')],
      [tools],
    )

    expect(items).toHaveLength(1)
    expect(items[0]).toMatchObject({ type: 'group', group: tools })
    expect(items[0].type === 'group' && items[0].routes.map(({ name }) => name)).toEqual([
      'time-tracking',
      'project-overview',
    ])
  })

  it('sorts routes inside a group by their own order', () => {
    const items = buildNavigationItems(
      [buildRoute('second', 200, 'tools'), buildRoute('first', 100, 'tools')],
      [tools],
    )

    expect(items[0].type === 'group' && items[0].routes.map(({ name }) => name)).toEqual([
      'first',
      'second',
    ])
  })

  it('positions the group by the group order, not by its routes', () => {
    const items = buildNavigationItems(
      [buildRoute('time-tracking', 100, 'tools'), buildRoute('dashboard', 200)],
      [tools],
    )

    expect(items.map((item) => (item.type === 'group' ? item.group.key : item.route.name))).toEqual(
      ['dashboard', 'tools'],
    )
  })

  it('defaults a missing route order to zero', () => {
    const items = buildNavigationItems([buildRoute('overviews'), buildRoute('dashboard', -100)], [])

    expect(items.map((item) => item.type === 'route' && item.route.name)).toEqual([
      'dashboard',
      'overviews',
    ])
  })

  it('warns and falls back to a top level entry for an unknown group', (context) => {
    context.skipConsole = true

    const items = buildNavigationItems([buildRoute('time-tracking', 100, 'toolz')], [tools])

    expect(items).toMatchObject([{ type: 'route' }])
    expect(console.warn).toHaveBeenCalledWith(expect.stringContaining('toolz'))
  })

  it('does not mutate the given routes', () => {
    const routes = [buildRoute('second', 200), buildRoute('first', 100)]

    buildNavigationItems(routes, [])

    expect(routes.map(({ name }) => name)).toEqual(['second', 'first'])
  })
})
