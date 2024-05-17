// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef, FormValues } from '#shared/components/Form/types.ts'
import type {
  TicketById,
  TicketLiveAppUser,
} from '#shared/entities/ticket/types.ts'
import type {
  TicketQuery,
  TicketQueryVariables,
} from '#shared/graphql/types.ts'
import type { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import type { ComputedRef, Ref, ShallowRef } from 'vue'

export interface TicketInformation {
  ticketQuery: QueryHandler<TicketQuery, TicketQueryVariables>
  initialFormTicketValue: FormValues
  ticket: ComputedRef<TicketById | undefined>
  newTicketArticleRequested: Ref<boolean>
  newTicketArticlePresent: Ref<boolean>
  form: ShallowRef<FormRef | undefined>
  updateFormLocation: (newLocation: string) => void
  canUpdateTicket: ComputedRef<boolean>
  showArticleReplyDialog: () => Promise<void>
  liveUserList?: Ref<TicketLiveAppUser[]>
  refetchingStatus: Ref<boolean>
  newArticlesIds: Set<string>
  scrollDownState: Ref<boolean>
  scrolledToBottom: Ref<boolean>
  updateRefetchingStatus: (newStatus: boolean) => void
}
