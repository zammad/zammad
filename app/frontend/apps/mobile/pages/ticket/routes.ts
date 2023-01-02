// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

import { ticketInformationRoutes } from './views/TicketInformation/plugins'

const routes: RouteRecordRaw[] = [
  {
    path: '/tickets/:internalId(\\d+)',
    name: 'TicketDetailView',
    props: true,
    component: () => import('./views/TicketDetailView.vue'),
    children: [
      {
        path: '',
        name: 'TicketDetailArticlesView',
        component: () => import('./views/TicketDetailArticlesView.vue'),
        props: true,
        meta: {
          title: __('Ticket'),
          requiresAuth: true,
          requiredPermission: ['ticket.agent', 'ticket.customer'],
          level: 3,
        },
      },
      {
        path: 'information',
        component: () =>
          import('./views/TicketInformation/TicketInformationView.vue'),
        name: 'TicketInformationView',
        props: true,
        children: ticketInformationRoutes,
        meta: {
          title: __('Ticket information'),
          requiresAuth: true,
          requiredPermission: ['ticket.agent', 'ticket.customer'],
          hasHeader: false,
          level: 4,
        },
      },
    ],
  },
  {
    path: '/tickets/view/:overviewLink?',
    name: 'TicketOverview',
    props: true,
    component: () => import('./views/TicketOverview.vue'),
    meta: {
      title: __('Tickets'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      hasBottomNavigation: true,
      level: 2,
    },
  },
  {
    path: '/tickets/create',
    name: 'TicketCreate',
    props: true,
    component: () => import('./views/TicketCreate.vue'),
    meta: {
      title: __('Create Ticket'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      level: 2,
    },
  },
]

export default routes
