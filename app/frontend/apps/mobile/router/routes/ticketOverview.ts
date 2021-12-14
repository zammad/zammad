// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import TicketOverview from '@mobile/views/TicketOverview.vue'
import { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw = {
  path: '/tickets',
  name: 'TicketOverview',
  props: true,
  component: TicketOverview,
  meta: {
    title: __('Ticket Overviews'),
    requiresAuth: true,
    requiredPermission: ['ticket.agent', 'ticket.customer'],
  },
}

export default route
