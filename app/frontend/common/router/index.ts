// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import authenticationGuard from '@common/router/guards/before/authentication'
import type { App } from 'vue'
import {
  createRouter,
  createWebHistory,
  Router,
  RouteRecordRaw,
} from 'vue-router'
import type { RouteRecordMeta } from '@common/types/router'
import permissionGuard from '@common/router/guards/before/permission'
import headerTitleGuard from '@common/router/guards/after/headerTitle'

declare module 'vue-router' {
  // eslint-disable-next-line @typescript-eslint/no-empty-interface
  interface RouteMeta extends RouteRecordMeta {}
}

export default function initializeRouter(
  app: App,
  routes: Array<RouteRecordRaw>,
): Router {
  const router: Router = createRouter({
    history: createWebHistory('mobile'),
    routes,
  })

  router.beforeEach(authenticationGuard)
  router.beforeEach(permissionGuard)

  router.afterEach(headerTitleGuard)

  app.use(router)

  return router
}
