// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '@shared/components/Form/composable'
import type { TicketQuery, TicketQueryVariables } from '@shared/graphql/types'
import type { QueryHandler } from '@shared/server/apollo/handler'
import type { ComputedRef, Ref, ShallowRef } from 'vue'
import { inject } from 'vue'
import type { TicketById } from '../types/tickets'

export const TICKET_INFORMATION_SYMBOL = Symbol('ticket')

interface TicketInformation {
  ticketQuery: QueryHandler<TicketQuery, TicketQueryVariables>
  ticket: ComputedRef<TicketById | undefined>
  form: ShallowRef<FormRef | undefined>
  formVisible: Ref<boolean>
  canSubmitForm: ComputedRef<boolean>
  canUpdateTicket: ComputedRef<boolean>
}

export const useTicketInformation = () => {
  return inject(TICKET_INFORMATION_SYMBOL) as TicketInformation
}
