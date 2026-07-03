// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref, toRef } from 'vue'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { useTicketEditTitle } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/composables/useTicketEditTitle.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

export const useTopBarHeader = () => {
  const isUpdatingTitle = ref(false)

  const { ticket, ticketId } = useTicketInformation()

  const { isTicketAgent, isTicketEditable } = useTicketView(ticket)

  const { copyToClipboard } = useCopyToClipboard()

  const { ticketNumber, ticketNumberWithTicketHook } = useTicketNumber(ticket)

  const config = toRef(useApplicationStore(), 'config')

  const copyTicketNumberToClipboard = () => {
    if (!ticketNumberWithTicketHook.value || !ticket.value?.internalId) return

    copyToClipboard([
      new ClipboardItem({
        'text/plain': ticketNumberWithTicketHook.value,
        'text/html': `<a href="${config.value.http_type}://${config.value.fqdn}/desktop/tickets/${ticket.value.internalId}">${ticketNumberWithTicketHook.value}</a>`,
      }),
    ])
  }

  const { updateTitle } = useTicketEditTitle(ticketId)

  return {
    ticket,
    ticketNumber,
    ticketNumberWithTicketHook,
    isTicketAgent,
    isTicketEditable,
    copyTicketNumberToClipboard,
    isUpdatingTitle,
    updateTitle,
  }
}
