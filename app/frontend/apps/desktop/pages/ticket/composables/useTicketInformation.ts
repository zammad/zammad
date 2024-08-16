// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type ComputedRef, inject, type InjectionKey } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'

interface TicketInformation {
  ticket: ComputedRef<TicketById | undefined>
  ticketId: ComputedRef<string>
}

export const TICKET_INFORMATION_KEY = Symbol(
  'ticket-information',
) as InjectionKey<TicketInformation>

export const useTicketInformation = () => {
  return inject(TICKET_INFORMATION_KEY) as TicketInformation
}
