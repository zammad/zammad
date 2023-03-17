// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { inject } from 'vue'
import type { TicketInformation } from '@mobile/entities/ticket/types'

export const TICKET_INFORMATION_SYMBOL = Symbol('ticket')

export const useTicketInformation = () => {
  return inject(TICKET_INFORMATION_SYMBOL) as TicketInformation
}
