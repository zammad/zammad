// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'
import type { TicketById } from '@mobile/pages/ticket/types/tickets'
import { useSessionStore } from '@shared/stores/session'

export const useTicketView = (ticket?: ComputedRef<TicketById | undefined>) => {
  const session = useSessionStore()

  // TODO: should be aligned, when we have the permission information.
  const isTicketAgent = computed(() => {
    return session.hasPermission('ticket.agent')
  })

  return { isTicketAgent }
}
