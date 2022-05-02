// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'
import LayoutMain from '@mobile/components/layout/LayoutMain.vue'
import transitionViewGuard from '@mobile/router/guards/before/viewTransition'
import type { ImportGlobEagerDefault } from '@common/types/utils'
import type { App } from 'vue'
import type { InitializeAppRouter } from '@common/types/router'
import mainInitializeRouter from '@common/router'

const routeModules = import.meta.globEager('./routes/*.ts')

const mainRoutes: Array<RouteRecordRaw> = []

Object.values(routeModules).forEach(
  (module: ImportGlobEagerDefault<RouteRecordRaw | Array<RouteRecordRaw>>) => {
    const defaultExport = module.default as
      | RouteRecordRaw
      | Array<RouteRecordRaw>

    if (Array.isArray(defaultExport)) {
      mainRoutes.push(...defaultExport)
    } else {
      mainRoutes.push(defaultExport)
    }
  },
)

export const routes: Array<RouteRecordRaw> = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@mobile/views/Login.vue'),
    meta: {
      title: __('Sign in'),
      requiresAuth: false,
      requiredPermission: null,
    },
  },
  {
    path: '/error',
    alias: '/:pathMatch(.*)*',
    name: 'Error',
    props: true,
    component: () => import('@mobile/views/Error.vue'),
    meta: {
      requiresAuth: false,
      requiredPermission: null,
    },
  },
  {
    path: '/',
    props: true,
    component: LayoutMain,
    children: mainRoutes,
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
