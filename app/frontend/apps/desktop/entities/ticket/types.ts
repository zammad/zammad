// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketById } from '#shared/entities/ticket/types.ts'

import type { ComputedRef, Ref } from 'vue'

export interface TicketInformation {
  ticket: ComputedRef<TicketById | undefined>
  ticketId: ComputedRef<ID>
  ticketInternalId: Ref<number>
}
