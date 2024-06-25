// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/tickets/create',
    name: 'TicketCreate',
    props: false,
    component: () => import('./views/TicketCreate.vue'),
    alias: ['/ticket/create', '/ticket/create/:pathMatch(.*)*'],
    meta: {
      title: __('New Ticket'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      level: 2,
    },
  },
]

export default route
