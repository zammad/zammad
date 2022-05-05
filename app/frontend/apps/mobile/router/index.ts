// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'
import LayoutMain from '@mobile/components/layout/LayoutMain/LayoutMain.vue'
import transitionViewGuard from '@mobile/router/guards/before/viewTransition'
import type { App } from 'vue'
import type { InitializeAppRouter, RoutesModule } from '@shared/types/router'
import mainInitializeRouter from '@shared/router'

const routeModules: Record<string, RoutesModule> = import.meta.globEager(
  '../modules/*/routes.ts',
)

const mainRoutes: Array<RouteRecordRaw> = []
const childRoutes: Array<RouteRecordRaw> = []

const handleRoutes = (routes: Array<RouteRecordRaw>, isMainRoute = false) => {
  if (isMainRoute) {
    mainRoutes.push(...routes)
  } else {
    childRoutes.push(...routes)
  }
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
    undefined,
    'mobile',
  )
}

export default initializeRouter
