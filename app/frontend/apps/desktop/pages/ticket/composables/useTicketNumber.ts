// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, type Ref } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

export const useTicketNumber = (ticket: Ref<TicketById | undefined>) => {
  const ticketNumber = computed(() => ticket?.value?.number?.toString())

  const { config } = storeToRefs(useApplicationStore())

  const ticketNumberWithTicketHook = computed(
    () =>
      ticketNumber.value && `${config.value.ticket_hook}${ticketNumber.value}`,
  )

  return {
    ticketNumber,
    ticketNumberWithTicketHook,
  }
}
