// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '@shared/stores/session'
import type { TicketById, TicketView } from '../types'

export const getTicketView = (ticket: TicketById) => {
  const session = useSessionStore()

  const isTicketEditable = ticket?.policy.update ?? false

  const isTicketCustomer =
    session.hasPermission('ticket.customer') && !ticket?.policy.agentReadAccess

  const isTicketAgent = ticket?.policy.agentReadAccess

  const ticketView: TicketView = isTicketAgent
    ? ('agent' as const)
    : ('customer' as const)

  return {
    isTicketAgent,
    isTicketCustomer,
    isTicketEditable,
    ticketView,
  }
}
