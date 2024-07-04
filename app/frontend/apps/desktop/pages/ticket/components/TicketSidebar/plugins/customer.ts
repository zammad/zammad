// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import TicketSidebarCustomerButton from '../TicketSidebarCustomerButton.vue'
import TicketSidebarCustomerContent from '../TicketSidebarCustomerContent.vue'

import type { TicketSidebarPlugin } from './types.ts'
import type { TicketSidebarContext } from '../../types.ts'

export default <TicketSidebarPlugin>{
  title: __('Customer'),
  buttonComponent: TicketSidebarCustomerButton,
  contentComponent: TicketSidebarCustomerContent,
  permissions: ['ticket.agent'],
  icon: 'person',
  order: 1000,
  available: (context: TicketSidebarContext) => {
    // Consider the sidebar available only if a customer ID has been set to an integer ID.
    //   In case of a string value, it's probably an unknown email address and therefore no customer to show.
    if (
      context.formValues.customer_id &&
      typeof context.formValues.customer_id === 'number'
    )
      return true

    return false
  },
}
