// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw = {
  path: '/error-tab',
  name: 'ErrorTab',
  component: () => import('../views/ErrorTab.vue'),
  meta: {
    requiresAuth: true,
    requiredPermission: null,
    hasOwnLandmarks: false,
  },
}

export default route
