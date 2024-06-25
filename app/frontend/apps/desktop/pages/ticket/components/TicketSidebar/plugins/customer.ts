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
    if (context.formValues.customer_id) return true
    return false
  },
}
