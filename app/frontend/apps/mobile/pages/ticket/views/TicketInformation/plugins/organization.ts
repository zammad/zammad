// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketInformationPlugin } from './index.ts'

export default <TicketInformationPlugin>{
  label: __('Organization'),
  route: {
    path: 'organization',
    name: 'TicketInformationOrganization',
    component: () => import('../TicketInformationOrganization.vue'),
    meta: {
      requiresAuth: true,
      requiredPermission: [],
    },
  },
  order: 300,
  condition: (ticket) => !!ticket?.organization,
}
