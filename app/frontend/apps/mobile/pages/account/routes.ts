// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/account',
    name: 'AccountOverview',
    props: true,
    component: () => import('./views/AccountOverview.vue'),
    meta: {
      title: __('Account'),
      requiresAuth: true,
      requiredPermission: ['*'],
      hasBottomNavigation: true,
      hasHeader: true,
      level: 1,
    },
  },
  {
    path: '/account/avatar',
    name: 'AccountAvatar',
    props: true,
    component: () => import('./views/AccountAvatar.vue'),
    meta: {
      title: __('Avatar'),
      requiresAuth: true,
      requiredPermission: ['user_preferences.avatar'],
      hasBottomNavigation: false,
      hasHeader: true,
      level: 2,
    },
  },
]

export default routes
