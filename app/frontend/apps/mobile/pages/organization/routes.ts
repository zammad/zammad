// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/organizations/:internalId',
    name: 'OrganizationDetailView',
    props: (route) => ({ internalId: Number(route.params.internalId) }),
    component: () => import('./views/OrganizationDetailView.vue'),
    meta: {
      title: __('Organization'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent'],
      hasBottomNavigation: true,
      hasHeader: true,
      level: 1,
    },
  },
]

export default routes
