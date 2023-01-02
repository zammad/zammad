// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { RouteRecordRaw } from 'vue-router'
import mainInitializeRouter from '@shared/router'
import type { InitializeAppRouter, RoutesModule } from '@shared/types/router'
import LayoutMain from '@mobile/components/layout/LayoutMain.vue'
import transitionViewGuard from './guards/before/viewTransition'
import { errorAfterGuard } from './error'

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
    name: 'Main',
    props: true,
    component: LayoutMain,
    children: childRoutes,
  },
]

const initializeRouter: InitializeAppRouter = (app: App) => {
  return mainInitializeRouter(
    app,
    routes,
    [transitionViewGuard],
    [errorAfterGuard],
    'mobile',
  )
}

export default initializeRouter
