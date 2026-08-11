// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  navigationGroups,
  type NavigationGroup,
} from '#desktop/components/PageNavigation/navigationGroups.ts'

import type { RouteRecordRaw } from 'vue-router'

interface RouteModule {
  default: RouteRecordRaw[]
}

export interface PageRoute {
  path: string
  name: string
  meta: {
    title: string
    // Addon routes do not have to define an order; it defaults to 0.
    order?: number
    icon: string
    requiredPermission: string[]
    requiresAuth: boolean
    canAccess?: () => boolean
    navigationGroup?: string
    [key: string]: unknown
  }
}

export type NavigationItem =
  | { type: 'route'; order: number; route: PageRoute }
  | { type: 'group'; order: number; group: NavigationGroup; routes: PageRoute[] }

// Both layouts the router discovers routes with (`routes.ts` and `routes/*.ts`),
//   at any depth so nested addon pages can reach the navigation too.
const routeFiles = import.meta.glob<RouteModule>(
  ['../../pages/**/routes.ts', '../../pages/**/routes/*.ts'],
  { eager: true, import: 'default' },
)

const routeValues = Object.values(routeFiles)
const mainNavigationRoutes: PageRoute[] = []

let permanentItemCount = 0

routeValues.forEach((routeModule) => {
  if (Array.isArray(routeModule)) {
    permanentItemCount += routeModule.filter(
      (route: RouteRecordRaw) => route.meta?.permanentItem,
    ).length

    const routes = routeModule.filter((route: RouteRecordRaw) => {
      return route.meta?.mainNavigation
    })
    if (!routes?.length) return

    const mappedRoutes = routes.map((route) => ({
      path: route.path,
      name: route.name,
      meta: route.meta,
    }))

    mainNavigationRoutes.push(...mappedRoutes)
  }
})

// Routes targeting the same group are collected into one item: their order
//   among each other is the route order, while the position of the group itself
//   is the group order.
export const buildNavigationItems = (routes: PageRoute[], groups: NavigationGroup[]) => {
  const items: NavigationItem[] = []
  const groupItems = new Map<string, NavigationItem & { type: 'group' }>()

  const sortedRoutes = [...routes].sort((a, b) => (a.meta.order ?? 0) - (b.meta.order ?? 0))

  sortedRoutes.forEach((route) => {
    const groupKey = route.meta.navigationGroup
    const group = groups.find(({ key }) => key === groupKey)

    if (!group) {
      // A typo or a missing addon would otherwise silently turn the entry into
      //   a top level one, which is exactly what the grouping avoids.
      if (groupKey && !import.meta.env.PROD) {
        console.warn(
          `Unknown navigation group "${groupKey}" for route ${route.path}, rendering it as a top level entry.`,
        )
      }

      items.push({ type: 'route', order: route.meta.order ?? 0, route })
      return
    }

    let groupItem = groupItems.get(group.key)
    if (!groupItem) {
      groupItem = { type: 'group', order: group.order, group, routes: [] }
      groupItems.set(group.key, groupItem)
      items.push(groupItem)
    }

    groupItem.routes.push(route)
  })

  return items.sort((a, b) => a.order - b.order)
}

const navigationItems = buildNavigationItems(mainNavigationRoutes, navigationGroups)

const numberOfPermanentItems = permanentItemCount

export { navigationItems, numberOfPermanentItems }
