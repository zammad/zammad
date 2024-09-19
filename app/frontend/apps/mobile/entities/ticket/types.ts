// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormRefParameter,
  FormValues,
} from '#shared/components/Form/types.ts'
import type {
  TicketById,
  TicketLiveAppUser,
} from '#shared/entities/ticket/types.ts'
import type {
  TicketWithMentionLimitQuery,
  TicketWithMentionLimitQueryVariables,
} from '#shared/graphql/types.ts'
import type { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import type { ComputedRef, Ref } from 'vue'

export interface TicketInformation {
  ticketQuery: QueryHandler<
    TicketWithMentionLimitQuery,
    TicketWithMentionLimitQueryVariables
  >
  initialFormTicketValue: Ref<FormValues | undefined>
  ticket: ComputedRef<TicketById | undefined>
  newTicketArticleRequested: Ref<boolean>
  newTicketArticlePresent: Ref<boolean>
  form: FormRefParameter
  updateFormLocation: (newLocation: string) => void
  isTicketEditable: ComputedRef<boolean>
  showArticleReplyDialog: () => Promise<void>
  liveUserList?: Ref<TicketLiveAppUser[]>
  refetchingStatus: Ref<boolean>
  newArticlesIds: Set<string>
  scrollDownState: Ref<boolean>
  scrolledToBottom: Ref<boolean>
  updateRefetchingStatus: (newStatus: boolean) => void
}
