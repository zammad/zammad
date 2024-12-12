// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

interface RouteModule {
  default: RouteRecordRaw[]
}

interface PageRoute {
  path: string
  name: string
  meta: {
    title: string
    order: number
    level: number
    icon: string
    requiredPermission: string[]
    requiresAuth: boolean
    [key: string]: unknown
  }
}

const routeFiles = import.meta.glob<RouteModule>('../../pages/**/routes.ts', {
  eager: true,
  import: 'default',
})

const routeValues = Object.values(routeFiles)
const firstLevelRoutes: PageRoute[] = []

let permanentItemCount = 0

routeValues.forEach((routeModule) => {
  if (Array.isArray(routeModule)) {
    permanentItemCount += routeModule.filter(
      (route: RouteRecordRaw) => route.meta?.permanentItem,
    ).length

    const routes = routeModule.filter((route: RouteRecordRaw) => {
      return route.meta?.level === 1
    })
    if (!routes?.length) return

    const mappedRoutes = routes.map((route) => ({
      path: route.path,
      name: route.name,
      meta: route.meta,
    }))

    firstLevelRoutes.push(...mappedRoutes)
  }
})

const sortedFirstLevelRoutes = firstLevelRoutes.sort(
  (a, b) => a.meta.order - b.meta.order,
)

const numberOfPermanentItems = permanentItemCount

export { firstLevelRoutes, sortedFirstLevelRoutes, numberOfPermanentItems }
