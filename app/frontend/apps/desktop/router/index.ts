// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import redirectGuard from '#shared/router/guards/before/redirect.ts'
import mainInitializeRouter from '#shared/router/index.ts'
import type { InitializeAppRouter, RoutesModule } from '#shared/types/router.ts'

import activeTaskbarTab from './guards/before/activeTaskbarTab.ts'
import systemSetupInfo from './guards/before/systemSetupInfo.ts'

import type { App } from 'vue'
import type { RouteRecordRaw } from 'vue-router'

const routeModules: Record<string, RoutesModule> = import.meta.glob(
  ['../pages/*/routes.ts', '../pages/*/routes/*.ts'],
  { eager: true },
)

const mainRoutes: Array<RouteRecordRaw> = []
const childRoutes: Array<RouteRecordRaw> = []

const names = new Set<string | symbol>()

const handleRoutes = (routes: Array<RouteRecordRaw>, isMainRoute = false) => {
  if (isMainRoute) {
    mainRoutes.push(...routes)
  } else {
    childRoutes.push(...routes)
  }

  if (import.meta.env.PROD) return

  // for debugging routes, vue-router doesn't do this automatically
  routes.forEach((route) => {
    if (!route.name) return

    if (names.has(route.name)) {
      console.error(
        `Duplicate route name: ${String(route.name)} for ${route.path}`,
      )
    } else {
      names.add(route.name)
    }
  })
}

Object.values(routeModules).forEach((module: RoutesModule) => {
  const defaultExport = module.default
  const { isMainRoute } = module

  handleRoutes(
    Array.isArray(defaultExport) ? defaultExport : [defaultExport],
    isMainRoute,
  )
})

export const routes: Array<RouteRecordRaw> = [
  ...mainRoutes,
  {
    path: '/',
    name: 'LayoutPage',
    component: () => import('#desktop/components/layout/LayoutPage.vue'),
    beforeEnter: redirectGuard,
    children: childRoutes,
  },
]

const initializeRouter: InitializeAppRouter = (app: App) => {
  return mainInitializeRouter(
    app,
    routes,
    [systemSetupInfo, activeTaskbarTab],
    [],
    'desktop',
  )
}

export default initializeRouter
