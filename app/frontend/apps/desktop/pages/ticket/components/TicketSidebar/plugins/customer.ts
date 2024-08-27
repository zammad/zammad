// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
  screens: [
    TicketSidebarScreenType.TicketDetailView,
    TicketSidebarScreenType.TicketCreate,
  ],
  icon: 'person',
  order: 1000,
  available: (context: TicketSidebarContext) => {
    // Consider the sidebar available only if a customer ID has been set to an integer ID.
    //   In case of a string value, it's probably an unknown email address and therefore no customer to show.
    return !!(
      context.formValues.customer_id &&
      typeof context.formValues.customer_id === 'number'
    )
  },
}
