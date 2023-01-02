// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/search/:type?',
    name: 'SearchOverview',
    props: true,
    component: () => import('./views/SearchOverview.vue'),
    meta: {
      title: __('Search'),
      requiresAuth: true,
      // TODO 2022-06-02 Sheremet V.A. rights?
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      hasBottomNavigation: true,
      level: 3,
    },
  },
]

export default routes
