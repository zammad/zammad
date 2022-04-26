// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw = {
  path: '/tickets',
  name: 'TicketOverview',
  props: true,
  component: () => import('@mobile/views/TicketOverview.vue'),
  meta: {
    title: __('Ticket Overviews'),
    requiresAuth: true,
    requiredPermission: ['ticket.agent', 'ticket.customer'],
    hasBottomNavigation: true,
    level: 2,
  },
}

export default route
