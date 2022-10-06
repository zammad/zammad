// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { TicketInformationPlugin } from './index'

export default <TicketInformationPlugin>{
  label: __('Customer'),
  route: {
    path: 'customer',
    name: 'TicketInformationCustomer',
    props: (route) => ({ internalId: Number(route.params.internalId) }),
    component: () => import('../TicketInformationCustomer.vue'),
    meta: {
      requiresAuth: true,
      requiredPermission: [],
    },
  },
  order: 200,
}
