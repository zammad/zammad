// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Home',
    props: true,
    component: () => import('./views/Home.vue'),
    meta: {
      title: __('Home'),
      requiresAuth: true,
      requiredPermission: ['*'],
      level: 1,
    },
  },
  {
    path: '/playground',
    name: 'Playground',
    props: true,
    component: () => import('./views/Playground.vue'),
    meta: {
      title: __('Home'),
      requiresAuth: true,
      requiredPermission: ['*'],
      level: 1,
    },
  },
]

export default route
