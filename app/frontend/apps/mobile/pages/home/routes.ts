// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Home',
    props: true,
    component: () => import('./views/Home.vue'),
    meta: {
      title: __('Home'),
      requiresAuth: true,
      requiredPermission: ['*'],
      hasBottomNavigation: true,
      level: 1,
    },
  },
  {
    path: '/favorite/ticker-overviews/edit',
    props: true,
    name: 'TicketOverviews',
    component: () => import('./views/FavoriteTicketOverviewsEdit.vue'),
    meta: {
      title: __('Ticket Overview'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      hasBottomNavigation: true,
      hasHeader: true,
      level: 2,
    },
  },
]

export default route
