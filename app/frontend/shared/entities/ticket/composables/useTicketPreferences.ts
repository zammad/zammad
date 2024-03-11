// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import type { JsonValue } from 'type-fest'
import { type TicketById } from '#shared/entities/ticket/types.ts'

export const useTicketPreferences = (ticket: Ref<TicketById | undefined>) => {
  const ticketPreferences = computed<Record<string, JsonValue>>(
    () => ticket.value?.preferences,
  )

  return { ticketPreferences }
}
