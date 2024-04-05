// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

import { personalSettingRoutes } from './views/PersonalSetting/plugins/index.ts'

const route: RouteRecordRaw[] = [
  {
    path: '/personal-setting',
    name: 'PersonalSettings',
    component: () => import('./views/PersonalSetting.vue'),
    meta: {
      title: __('Profile'),
      icon: 'person-gear',
      requiresAuth: true,
      requiredPermission: ['*'],
      level: 2,
    },
    children: personalSettingRoutes,
  },
]

export default route
