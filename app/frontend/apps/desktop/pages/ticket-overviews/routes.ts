// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/tickets/view/:overviewLink?',
    name: 'TicketOverview',
    component: () => import('./views/TicketOverviews.vue'),
    alias:
      // Temporary until we work on the dashboard
      import.meta.env.DEV || VITE_TEST_MODE
        ? '/ticket/view/:overviewLink?'
        : ['/', '/ticket/view/:overviewLink?'],
    props: true,
    meta: {
      title: __('Overviews'),
      requiresAuth: true,
      icon: 'all-tickets',
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      level: 1,
      pageKey: 'ticket-overviews',
      permanentItem: true,
    },
  },
]

export default route
