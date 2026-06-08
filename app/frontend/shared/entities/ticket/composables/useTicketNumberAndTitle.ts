// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef, type Ref } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import type { TicketById } from '../types.ts'

export const useTicketNumberAndTitle = (ticket?: Ref<Partial<TicketById> | undefined>) => {
  const config = toRef(useApplicationStore(), 'config')

  const getTicketNumberWithHook = (ticketNumber?: number | string) => {
    if (!ticketNumber) return ''
    return `${config.value.ticket_hook}${ticketNumber}`
  }

  const getTicketNumberWithTitle = (ticketNumber?: number | string, ticketTitle?: string) => {
    if (!ticketNumber || !ticketTitle) return ''
    return `${getTicketNumberWithHook(ticketNumber)} - ${ticketTitle}`
  }

  const ticketNumberWithHook = computed(() => getTicketNumberWithHook(ticket?.value?.number))

  const ticketNumberWithTitle = computed(() =>
    getTicketNumberWithTitle(ticket?.value?.number, ticket?.value?.title),
  )

  return {
    ticketNumberWithHook,
    ticketNumberWithTitle,
    getTicketNumberWithHook,
    getTicketNumberWithTitle,
  }
}
