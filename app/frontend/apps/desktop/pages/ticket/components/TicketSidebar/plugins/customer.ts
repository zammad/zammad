// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  TicketSidebarScreenType,
  type TicketSidebarContext,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarCustomer from '../TicketSidebarCustomer/TicketSidebarCustomer.vue'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Customer'),
  component: TicketSidebarCustomer,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketDetailView, TicketSidebarScreenType.TicketCreate],
  views: ['agent'],
  icon: 'user',
  order: 1000,
  available: (context: TicketSidebarContext) => {
    // A known customer always arrives as a numeric ID. A string is an unknown email address or
    //   phone number, even one made of digits only, so there is no customer to show yet.
    const customerId = context.formValues.customer_id

    return !!(customerId && typeof customerId === 'number')
  },
}
