// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef, type Ref } from 'vue'

import {
  createLinkClipboardItem,
  useCopyToClipboard,
} from '#shared/composables/useCopyToClipboard.ts'
import type { TicketLabel } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

export const useTicketNumber = (ticket: Ref<TicketLabel | undefined>) => {
  const ticketNumber = computed(() => ticket?.value?.number?.toString())

  const config = toRef(useApplicationStore(), 'config')

  const ticketNumberWithTicketHook = computed(
    () => ticketNumber.value && `${config.value.ticket_hook}${ticketNumber.value}`,
  )

  const { copyToClipboard } = useCopyToClipboard()

  const copyTicketNumberToClipboard = () => {
    if (!ticketNumberWithTicketHook.value || !ticket.value?.internalId) return

    copyToClipboard([
      createLinkClipboardItem(
        `${config.value.http_type}://${config.value.fqdn}/desktop/tickets/${ticket.value.internalId}`,
        ticketNumberWithTicketHook.value,
      ),
    ])
  }

  return {
    ticketNumber,
    ticketNumberWithTicketHook,
    copyTicketNumberToClipboard,
  }
}
