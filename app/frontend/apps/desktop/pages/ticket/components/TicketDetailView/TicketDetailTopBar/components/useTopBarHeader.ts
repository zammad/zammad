// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { isSystemUser } from '#shared/entities/user/utils/isSystemUser.ts'

import { useTicketNumber } from '#desktop/entities/ticket/composables/useTicketNumber.ts'
import { useTicketEditTitle } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/composables/useTicketEditTitle.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

export const useTopBarHeader = () => {
  const isUpdatingTitle = ref(false)

  const { ticket, ticketId } = useTicketInformation()

  const { isTicketAgent, isTicketEditable } = useTicketView(ticket)

  const { ticketNumber, ticketNumberWithTicketHook, copyTicketNumberToClipboard } =
    useTicketNumber(ticket)

  const isSystemCustomer = computed(() => isSystemUser(ticket.value?.customer))

  const { updateTitle } = useTicketEditTitle(ticketId)

  return {
    ticket,
    ticketNumber,
    ticketNumberWithTicketHook,
    isTicketAgent,
    isTicketEditable,
    isSystemCustomer,
    copyTicketNumberToClipboard,
    isUpdatingTitle,
    updateTitle,
  }
}
