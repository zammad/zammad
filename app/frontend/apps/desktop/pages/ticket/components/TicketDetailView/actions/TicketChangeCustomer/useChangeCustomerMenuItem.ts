// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const { open } = useFlyout({
  name: 'change-customer',
  component: () => import('./TicketChangeCustomerFlyout.vue'),
})

export const useChangeCustomerMenuItem = () => {
  const { ticket } = useTicketInformation()
  const { isTicketAgent, isTicketEditable } = useTicketView(ticket)

  const FLYOUT_KEY = 'change-customer'

  const customerChangeMenuItem: MenuItem = {
    key: FLYOUT_KEY,
    label: __('Change customer'),
    icon: 'person',
    show: () => isTicketAgent.value && isTicketEditable.value,
    onClick: () => {
      open({
        ticket,
        name: FLYOUT_KEY,
      })
    },
  }
  return {
    customerChangeMenuItem,
  }
}
