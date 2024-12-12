// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/dashboard',
    name: 'Dashboard',
    alias: '/',
    props: true,
    component: () => import('./views/Dashboard.vue'),
    meta: {
      title: __('Dashboard'),
      requiresAuth: true,
      icon: 'speedometer2',
      requiredPermission: ['*'],
      order: 0,
      level: 1,
      permanentItem: true,
    },
  },
  {
    path: '/playground',
    name: 'Playground',
    props: true,
    component: () => import('./views/Playground.vue'),
    meta: {
      title: 'Playground',
      icon: 'logo-flat',
      requiresAuth: true,
      requiredPermission: ['*'],
      order: 500,
    },
  },
]

export default route
