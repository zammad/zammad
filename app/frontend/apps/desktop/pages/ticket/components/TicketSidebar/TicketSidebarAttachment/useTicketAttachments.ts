// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketAttachmentsQuery } from '#desktop/pages/ticket/graphql/queries/ticketAttachments.api.ts'

import type { WatchQueryFetchPolicy } from '@apollo/client/core'

export const useTicketAttachments = (fetchPolicy?: WatchQueryFetchPolicy) => {
  const { ticketId } = useTicketInformation()

  const ticketAttachmentsQuery = new QueryHandler(
    useTicketAttachmentsQuery(
      () => ({
        ticketId: ticketId.value,
      }),
      { fetchPolicy },
    ),
  )
  const result = ticketAttachmentsQuery.result()
  const loading = ticketAttachmentsQuery.loading()

  const ticketAttachments = computed(() => {
    if (!result.value?.ticketAttachments) return []

    return result.value?.ticketAttachments
  })

  return {
    ticketAttachmentsQuery,
    ticketAttachments,
    loading,
  }
}
