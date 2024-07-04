// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import {
  type TicketSharedDraftStartListQuery,
  type TicketSharedDraftStartUpdateByGroupSubscription,
  type TicketSharedDraftStartUpdateByGroupSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { GraphQLHandlerError } from '#shared/types/error.ts'

import { useTicketSharedDraftStartListQuery } from '../graphql/queries/ticketSharedDraftStartList.api.ts'
import { TicketSharedDraftStartUpdateByGroupDocument } from '../graphql/subscriptions/ticketSharedDraftStartUpdateByGroup.api.ts'

export const useTicketSharedDraftStart = (
  groupId: Ref<string>,
  errorCallback?: (error: GraphQLHandlerError) => boolean,
) => {
  const sharedDraftStartListQuery = new QueryHandler(
    useTicketSharedDraftStartListQuery(
      () => ({
        groupId: groupId.value,
      }),
      // Commented out because cache-first policy breaks subscribing to updates.
      {
        fetchPolicy: 'cache-first',
      },
    ),
    {
      errorCallback,
    },
  )

  const sharedDraftStartListResult = sharedDraftStartListQuery.result()
  const loading = sharedDraftStartListQuery.loading()

  const sharedDraftStartList = computed(
    () => sharedDraftStartListResult.value?.ticketSharedDraftStartList,
  )

  sharedDraftStartListQuery.subscribeToMore<
    TicketSharedDraftStartUpdateByGroupSubscriptionVariables,
    TicketSharedDraftStartUpdateByGroupSubscription
  >(() => ({
    document: TicketSharedDraftStartUpdateByGroupDocument,
    variables: {
      groupId: groupId.value,
    },
    updateQuery: (_, { subscriptionData }) => {
      if (
        !subscriptionData.data?.ticketSharedDraftStartUpdateByGroup
          ?.sharedDraftStarts
      ) {
        return null as unknown as TicketSharedDraftStartListQuery
      }

      return {
        ticketSharedDraftStartList:
          subscriptionData.data.ticketSharedDraftStartUpdateByGroup
            .sharedDraftStarts,
      }
    },
  }))

  return {
    loading,
    sharedDraftStartList,
    sharedDraftStartListQuery,
  }
}
