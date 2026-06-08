// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { openFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useHistoryFlyout } from '#desktop/components/CommonHistoryFlyout/useHistoryFlyout.ts'
import { useTicketHistoryQuery } from '#desktop/pages/ticket/graphql/queries/ticketHistory.api.ts'

export const TICKET_HISTORY_FLYOUT_NAME = 'ticket-history'

export const openTicketHistoryFlyout = (ticketId: string) => {
  openFlyout(TICKET_HISTORY_FLYOUT_NAME, {
    name: TICKET_HISTORY_FLYOUT_NAME,
    type: EnumObjectManagerObjects.Ticket,
    query: () => useTicketHistoryQuery(() => ({ ticketId })),
  })
}

export const useTicketHistory = () => {
  useHistoryFlyout(TICKET_HISTORY_FLYOUT_NAME, EnumObjectManagerObjects.Ticket)

  return { openTicketHistoryFlyout }
}
