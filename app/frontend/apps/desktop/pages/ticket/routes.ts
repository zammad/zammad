// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/tickets/create/:tabId?',
    name: 'TicketCreate',
    props: true,
    component: () => import('./views/TicketCreate.vue'),
    alias: ['/ticket/create/:tabId?', '/ticket/create/:pathMatch(.*)*'],
    meta: {
      title: __('New Ticket'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      level: 2,
    },
  },
  {
    path: '/tickets/:internalId(\\d+)',
    alias: ['/ticket/:internalId(\\d+)', '/ticket/zoom/:internalId(\\d+)'],
    name: 'TicketDetail',
    // :todo check/clarify for available ticket id
    props: true,
    component: () => import('./views/TicketDetailView.vue'),
    meta: {
      title: __('Ticket Detail'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      level: 2,
    },
  },
  {
    path: '/ticket/zoom/:internalId(\\d+)/:articleId(\\d+)',
    redirect: (to) =>
      `/tickets/${to.params.internalId}#article-${to.params.articleId}`,
  },
]

export default route
