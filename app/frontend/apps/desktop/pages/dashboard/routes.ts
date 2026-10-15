// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { markRaw } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import DashboardNavigationItem from './components/DashboardNavigationItem.vue'

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/playground',
    name: 'Playground',
    props: true,
    component: () => import('./views/Playground.vue'),
    meta: {
      title: 'Playground',
      icon: 'logo-flat',
      requiresAuth: true,
      requiredPermission: ['admin'],
      order: 500,
    },
  },
]

// Temporary until we work on the dashboard
if (import.meta.env.DEV || VITE_TEST_MODE) {
  route.push({
    path: '/dashboard',
    name: 'Dashboard',
    alias: '/',
    props: true,
    component: () => import('./views/Dashboard.vue'),
    // A redirect instead of `canAccess`, which would show the forbidden page right after the login.
    beforeEnter: () => {
      if (useApplicationStore().config.dashboard) return true

      return { name: 'TicketOverview' }
    },
    meta: {
      title: __('Dashboard'),
      requiresAuth: true,
      icon: 'speedometer2',
      requiredPermission: ['*'],
      order: 0,
      mainNavigation: true,
      navigationItemComponent: markRaw(DashboardNavigationItem),
      permanentItem: true,
    },
  })
}

export default route
