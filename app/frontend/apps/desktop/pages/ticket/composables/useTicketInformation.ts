// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type ComputedRef, inject, type InjectionKey } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'

export const TICKET_INFORMATION_KEY = Symbol(
  'ticket-information',
) as InjectionKey<ComputedRef<TicketById | undefined>>

export const useTicketInformation = () => {
  const ticket = inject(TICKET_INFORMATION_KEY) as ComputedRef<TicketById>

  return {
    ticket,
  }
}
