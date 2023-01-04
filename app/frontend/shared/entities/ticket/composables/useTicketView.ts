// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import type { TicketById } from '@mobile/pages/ticket/types/tickets'
import { useSessionStore } from '@shared/stores/session'

export const useTicketView = (ticket: Ref<TicketById | undefined>) => {
  const session = useSessionStore()

  const isTicketEditable = computed(() => {
    return ticket.value?.policy.update ?? false
  })

  const isTicketCustomer = computed(() => {
    return (
      session.hasPermission('ticket.customer') &&
      !session.hasPermission('ticket.agent') &&
      !!ticket.value
    )
  })

  const isTicketAgent = computed(() => {
    return session.hasPermission('ticket.agent') && !!ticket.value
  })

  return { isTicketAgent, isTicketCustomer, isTicketEditable }
}
