// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { usePersonalSettingStore } from './stores/personalSetting.ts'
import { personalSettingRoutes } from './views/PersonalSetting/plugins/index.ts'

import type { RouteRecordRaw } from 'vue-router'

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
      pageKey: 'personal-setting',
      permanentItem: true,
    },
    children: personalSettingRoutes,
    redirect: () => ({
      path: usePersonalSettingStore().previousPersonalSettingPath,
    }),
  },
]

export default route
