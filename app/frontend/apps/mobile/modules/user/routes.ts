// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw = {
  path: '/',
  name: 'UserOverview',
  props: true,
  component: () => import('./views/UserOverview.vue'),
  meta: {
    title: __('Customer'), // TODO name?
    requiresAuth: true,
    requiredPermission: ['*'],
    hasBottomNavigation: true,
    level: 1,
  },
}

export default route
