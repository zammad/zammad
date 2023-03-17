// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import {
  createRouter,
  createWebHistory,
  type NavigationGuard,
  type NavigationHookAfter,
  type Router,
  type RouteRecordRaw,
} from 'vue-router'
import type { RouteRecordMeta } from '@shared/types/router'
import authenticationGuard from './guards/before/authentication'
import permissionGuard from './guards/before/permission'
import headerTitleGuard from './guards/after/headerTitle'
import { initializeWalker } from './walker'

declare module 'vue-router' {
  // eslint-disable-next-line @typescript-eslint/no-empty-interface
  interface RouteMeta extends RouteRecordMeta {}
}

export default function initializeRouter(
  app: App,
  routes: Array<RouteRecordRaw>,
  beforeGuards?: NavigationGuard[],
  afterGuards?: NavigationHookAfter[],
  historyBase?: string,
): Router {
  const router: Router = createRouter({
    history: createWebHistory(historyBase),
    routes,
  })

  router.beforeEach(authenticationGuard)
  router.beforeEach(permissionGuard)

  beforeGuards?.forEach((guard) => router.beforeEach(guard))

  router.afterEach(headerTitleGuard)

  afterGuards?.forEach((guard) => router.afterEach(guard))

  app.use(router)

  initializeWalker(app, router)

  return router
}
