// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedRef } from 'vue'
import { inject } from 'vue'
import type { TicketById } from '../../../types/tickets'

export const TICKET_INFORMATION_SYMBOL = Symbol('ticket')

export const useTicketInformation = () => {
  return inject(TICKET_INFORMATION_SYMBOL) as ComputedRef<Maybe<TicketById>>
}
