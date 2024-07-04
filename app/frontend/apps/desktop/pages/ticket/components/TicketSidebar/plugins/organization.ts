// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import TicketSidebarOrganizationButton from '../TicketSidebarOrganizationButton.vue'
// eslint-disable-next-line import/no-named-as-default,import/no-named-as-default-member
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
    // Consider the sidebar available only if a customer ID has been set to an integer ID.
    //   In case of a string value, it's probably an unknown email address and therefore no organization to show.
    if (
      context.formValues.customer_id &&
      typeof context.formValues.customer_id === 'number'
    )
      return true

    return false
  },
}
