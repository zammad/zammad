// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, toValue } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { MaybeRefOrGetter } from '@vueuse/core'

export const useTicketNumber = (
  ticket: MaybeRefOrGetter<TicketById | undefined>,
) => {
  const ticketNumber = computed(() => toValue(ticket)?.number?.toString())

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
