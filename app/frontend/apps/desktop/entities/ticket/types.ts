// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormRefParameter } from '#shared/components/Form/types.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'

import type { ComputedRef, Ref } from 'vue'

export interface TicketInformation {
  ticket: ComputedRef<TicketById | undefined>
  ticketId: ComputedRef<ID>
  ticketInternalId: Ref<number>
  isTicketEditable: ComputedRef<boolean>
  form: FormRefParameter
  showTicketArticleReplyForm: () => void
  newTicketArticlePresent: Ref<boolean | undefined>
}
