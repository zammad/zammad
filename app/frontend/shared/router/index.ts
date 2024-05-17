// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  createRouter,
  createWebHistory,
  type NavigationGuard,
  type NavigationHookAfter,
  type Router,
  type RouteRecordRaw,
} from 'vue-router'

import { useApplicationStore } from '#shared/stores/application.ts'
import type { RouteRecordMeta } from '#shared/types/router.ts'

import { errorAfterGuard } from './error.ts'
import headerTitleGuard from './guards/after/headerTitle.ts'
import authenticationGuard from './guards/before/authentication.ts'
import permissionGuard from './guards/before/permission.ts'
import { initializeWalker } from './walker.ts'

import type { App } from 'vue'

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

  const removeInitializer = router.beforeResolve(() => {
    const { setInitialized } = useApplicationStore()
    setInitialized()
    removeInitializer()
  })

  router.beforeEach(authenticationGuard)
  router.beforeEach(permissionGuard)

  beforeGuards?.forEach((guard) => router.beforeEach(guard))

  router.afterEach(headerTitleGuard)
  router.afterEach(errorAfterGuard)

  afterGuards?.forEach((guard) => router.afterEach(guard))

  app.use(router)

  initializeWalker(app, router)

  return router
}
