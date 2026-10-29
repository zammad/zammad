// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import type { TicketInformation } from '#desktop/entities/ticket/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  type TicketSidebarContext,
  TicketSidebarScreenType,
} from '#desktop/pages/ticket/types/sidebar.ts'

import type { ComputedRef } from 'vue'

const CUSTOMER_FLYOUT_KEY = 'ticket-change-customer'

export const useChangeCustomerMenuItem = (context: TicketSidebarContext): MenuItem => {
  const { open: openChangeCustomerFlyout } = useFlyout({
    name: CUSTOMER_FLYOUT_KEY,
    component: () =>
      import('#desktop/pages/ticket/components/TicketDetailView/actions/TicketChangeCustomer/TicketChangeCustomerFlyout.vue'),
  })

  let ticket: TicketInformation['ticket']
  let isTicketAgent: ComputedRef<boolean>
  let isTicketEditable: ComputedRef<boolean>

  // :TODO find a way to provide the ticket via prop
  if (context.screenType === TicketSidebarScreenType.TicketDetailView) {
    ;({ ticket } = useTicketInformation())
    ;({ isTicketAgent, isTicketEditable } = useTicketView(ticket))
  }

  return {
    key: CUSTOMER_FLYOUT_KEY,
    label: __('Change customer'),
    icon: 'user',
    show: () => ticket && isTicketAgent.value && isTicketEditable.value,
    onClick: () =>
      openChangeCustomerFlyout({
        ticket,
      }),
  }
}
