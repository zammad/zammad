// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { markRaw } from 'vue'

import CallerLogNavigationItem from './components/CallerLogNavigationItem.vue'

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/cti',
    name: 'CallerLog',
    component: () => import('./views/CallerLog.vue'),
    meta: {
      title: __('Caller log'),
      requiresAuth: true,
      requiredPermission: ['cti.agent'],
      icon: 'telephone',
      mainNavigation: true,
      order: 400,
      // The entry carries the counter and the caller notification switch, and
      //   hides itself without a CTI backend while the page stays reachable.
      navigationItemComponent: markRaw(CallerLogNavigationItem),
      pageKey: 'cti',
      permanentItem: true,
    },
  },
]

export default route
