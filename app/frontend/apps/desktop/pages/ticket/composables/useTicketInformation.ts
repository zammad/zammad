// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type ComputedRef, inject, type InjectionKey } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'

export const TICKET_INFORMATINO_KEY = Symbol(
  __('Ticket Information Injection Key'),
) as InjectionKey<ComputedRef<TicketById | undefined>>

export const useTicketInformation = () => {
  const ticket = inject(TICKET_INFORMATINO_KEY, null)

  return {
    ticket,
  }
}
