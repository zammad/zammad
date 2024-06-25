// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import TicketSidebarOrganizationButton from '../TicketSidebarOrganizationButton.vue'
import TicketSidebarOrganizationContent from '../TicketSidebarOrganizationContent.vue'

import type { TicketSidebarPlugin } from './types.ts'
import type { TicketSidebarContext } from '../../types.ts'

export default <TicketSidebarPlugin>{
  title: __('Organization'),
  buttonComponent: TicketSidebarOrganizationButton,
  contentComponent: TicketSidebarOrganizationContent,
  permissions: ['ticket.agent'],
  icon: 'buildings',
  order: 2000,
  available: (context: TicketSidebarContext) => {
    // When customer_id is selected, then it's
    // possible that organization sidebar needs to be shown.
    if (context.formValues.customer_id) return true
    return false
  },
}
