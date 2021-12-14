// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { RouteRecordRaw } from 'vue-router'
import Login from '@mobile/views/Login.vue'
import Error from '@mobile/views/Error.vue'
import LayoutMain from '@mobile/components/layout/LayoutMain.vue'
import { ImportGlobEagerDefault } from '@common/types/utils'

const routeModules = import.meta.globEager('./routes/*.ts')

const mainRoutes: Array<RouteRecordRaw> = []

Object.values(routeModules).forEach((module: ImportGlobEagerDefault) => {
  const defaultExport = module.default as RouteRecordRaw | Array<RouteRecordRaw>

  if (Array.isArray(defaultExport)) {
    mainRoutes.push(...defaultExport)
  } else {
    mainRoutes.push(defaultExport)
  }
})

const routes: Array<RouteRecordRaw> = [
  {
    path: '/login',
    name: 'Login',
    props: true,
    component: Login,
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
    component: Error,
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

export default routes
