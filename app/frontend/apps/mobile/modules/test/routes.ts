// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable zammad/zammad-detect-translatable-string */

import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/test',
    name: 'TestOverview',
    props: true,
    component: () => import('./views/TestOverview.vue'),
    meta: {
      title: 'Home',
      requiresAuth: true,
      requiredPermission: ['*'],
      hasBottomNavigation: true,
      level: 2,
    },
  },
]

export default routes
