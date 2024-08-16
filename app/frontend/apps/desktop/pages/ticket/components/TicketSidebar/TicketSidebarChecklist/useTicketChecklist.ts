// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type {
  ChecklistItem,
  TicketChecklistQuery,
  TicketChecklistUpdatesSubscription,
  TicketChecklistUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.api.ts'
import { TicketChecklistUpdatesDocument } from '#desktop/pages/ticket/graphql/subscriptions/ticketChecklistUpdates.api.ts'

export const useTicketChecklist = (
  subscriptionUpdateCallback?: (
    previousChecklist: ChecklistItem[],
    newChecklist: ChecklistItem[],
  ) => void,
) => {
  const { ticketId, ticket } = useTicketInformation()

  const readOnly = computed(() => !ticket.value?.policy.update)

  const checklistQuery = new QueryHandler(
    useTicketChecklistQuery(
      () => ({
        ticketId: ticketId.value,
      }),
      {
        fetchPolicy: 'cache-and-network',
      },
    ),
    {
      errorCallback: (error) => error.type !== GraphQLErrorTypes.RecordNotFound,
    },
  )

  const checklistResult = checklistQuery.result()
  const isLoadingChecklist = checklistQuery.loading()

  const checklist = computed(() => checklistResult.value?.ticketChecklist)

  const incompleteItemCount = computed(
    () => checklistResult.value?.ticketChecklist?.incomplete,
  )

  checklistQuery.subscribeToMore<
    TicketChecklistUpdatesSubscriptionVariables,
    TicketChecklistUpdatesSubscription
  >(() => ({
    document: TicketChecklistUpdatesDocument,
    variables: {
      ticketId: ticketId.value as string,
    },
    updateQuery: (prev, { subscriptionData }) => {
      if (!subscriptionData.data.ticketChecklistUpdates)
        return null as unknown as TicketChecklistQuery

      const { ticketChecklist } = subscriptionData.data.ticketChecklistUpdates

      if (
        checklist.value?.items?.length &&
        ticketChecklist?.items?.length &&
        subscriptionUpdateCallback
      )
        subscriptionUpdateCallback(
          checklistResult.value?.ticketChecklist?.items as ChecklistItem[],
          ticketChecklist.items as ChecklistItem[],
        )

      return {
        ticketChecklist,
      }
    },
  }))

  return {
    checklist,
    incompleteItemCount,
    readOnly,
    isLoadingChecklist,
  }
}
