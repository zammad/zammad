// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import gql from 'graphql-tag'
import { uniq } from 'lodash-es'
import { computed, inject, provide, ref, toRef } from 'vue'

import { getApolloClient } from '#shared/server/apollo/client.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import { useFlyout } from '../../CommonFlyout/useFlyout.ts'

import type { TicketBulkEditReturn } from './types.ts'

const TICKET_BULK_EDIT_SYMBOL = Symbol('ticket-bulk-edit')

export interface TicketBulkOverviewContext {
  overviewId: ID
  searchQuery?: never
}

export interface TicketBulkSearchContext {
  overviewId?: never
  searchQuery: string
}

export const useTicketBulkEdit = () => {
  const injectBulkEdit = inject<Maybe<TicketBulkEditReturn>>(TICKET_BULK_EDIT_SYMBOL, null)

  const isBulkTaskRunning = toRef(useTicketBulkUpdateStore(), 'isRunning')

  if (injectBulkEdit) return injectBulkEdit

  const apolloClient = getApolloClient()

  const checkedTicketIds = ref<Set<ID>>(new Set())

  const selectAllActive = ref(false)

  const bulkCount = ref(0)

  const bulkHasMoreItems = ref(false)

  const bulkContext = ref<TicketBulkOverviewContext | TicketBulkSearchContext>()

  const ticketIds = computed<ID[]>(() => Array.from(checkedTicketIds.value.keys()))

  const groupIds = computed(() => {
    const ids = ticketIds.value.map((ticketId) => {
      const cache = apolloClient.cache.readFragment<{ group: { id: ID } }>({
        id: `Ticket:${ticketId}`,
        fragment: gql`
          fragment groupId on Ticket {
            id
            group {
              id
            }
          }
        `,
      })

      return cache?.group.id ?? ''
    })

    return uniq(ids)
  })

  const { hasPermission } = useSessionStore()

  const bulkEditActive = computed(() => hasPermission('ticket.agent'))

  let onSuccessCallback: (() => void) | undefined
  let onFailureCallback: ((invalidTicketIds: ID[]) => void) | undefined

  const { open } = useFlyout({
    name: 'tickets-bulk-edit',
    component: () =>
      import('#desktop/components/Ticket/TicketBulkEditFlyout/TicketBulkEditFlyout.vue'),
  })

  const openBulkEditFlyout = () => {
    open({
      ticketIds,
      bulkCount,
      bulkHasMoreItems,
      bulkContext,
      groupIds,
      onSuccess: () => {
        checkedTicketIds.value.clear()
        selectAllActive.value = false
        onSuccessCallback?.()
      },
      onFailure: (invalidTicketIds: ID[]) => {
        checkedTicketIds.value = new Set(invalidTicketIds)
        selectAllActive.value = false
        onFailureCallback?.(invalidTicketIds)
      },
    })
  }

  const provideBulkEdit = {
    bulkEditActive,
    isBulkTaskRunning,
    checkedTicketIds,
    groupIds,
    selectAllActive,
    bulkCount,
    bulkHasMoreItems,
    bulkContext,
    openBulkEditFlyout,
    setOnSuccessCallback: (callback: () => void) => {
      onSuccessCallback = callback
    },
    onSuccessCallback,
    setOnFailureCallback: (callback: () => void) => {
      onFailureCallback = callback
    },
    onFailureCallback,
  }

  provide(TICKET_BULK_EDIT_SYMBOL, provideBulkEdit)

  return provideBulkEdit
}
