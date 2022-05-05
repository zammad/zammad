// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import authenticationGuard from '@shared/router/guards/before/authentication'
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
import permissionGuard from '@shared/router/guards/before/permission'
import headerTitleGuard from '@shared/router/guards/after/headerTitle'

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

  return router
}
