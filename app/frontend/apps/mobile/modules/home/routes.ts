// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw = {
  path: '/',
  name: 'Home',
  props: true,
  component: () => import('./views/Home.vue'),
  meta: {
    title: __('Home'),
    requiresAuth: true,
    requiredPermission: ['*'],
    hasBottomNavigation: true,
    level: 1,
  },
}

export default route
