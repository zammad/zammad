// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import redirectGuard from '#shared/router/guards/before/redirect.ts'

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Home',
    props: true,
    component: () => import('./views/Home.vue'),
    beforeEnter: redirectGuard,
    meta: {
      title: __('Home'),
      requiresAuth: true,
      requiredPermission: ['*'],
      hasBottomNavigation: true,
      level: 1,
    },
  },
  {
    path: '/favorite/ticket-overviews/edit',
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
