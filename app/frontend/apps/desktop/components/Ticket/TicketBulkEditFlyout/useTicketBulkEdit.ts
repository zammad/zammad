// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import gql from 'graphql-tag'
import { computed, inject, provide, ref } from 'vue'

import { getApolloClient } from '#shared/server/apollo/client.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useFlyout } from '../../CommonFlyout/useFlyout.ts'

import type { TicketBulkEditReturn } from './types.ts'

const TICKET_BULK_EDIT_SYMBOL = Symbol('ticket-bulk-edit')

export const useTicketBulkEdit = () => {
  const injectBulkEdit = inject<Maybe<TicketBulkEditReturn>>(
    TICKET_BULK_EDIT_SYMBOL,
    null,
  )

  if (injectBulkEdit) return injectBulkEdit

  const apolloClient = getApolloClient()

  const checkedTicketIds = ref<Set<ID>>(new Set())

  const ticketIds = computed<ID[]>(() =>
    Array.from(checkedTicketIds.value.keys()),
  )

  const groupIds = computed(() =>
    ticketIds.value.map((ticketId) => {
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
    }),
  )

  const { hasPermission } = useSessionStore()

  const bulkEditActive = computed(() => hasPermission('ticket.agent'))

  let onSuccessCallback: (() => void) | undefined

  const { open } = useFlyout({
    name: 'tickets-bulk-edit',
    component: () =>
      import(
        '#desktop/components/Ticket/TicketBulkEditFlyout/TicketBulkEditFlyout.vue'
      ),
  })

  const openBulkEditFlyout = () => {
    open({
      ticketIds,
      groupIds,
      onSuccess: () => {
        checkedTicketIds.value.clear()
        onSuccessCallback?.()
      },
    })
  }

  const provideBulkEdit = {
    bulkEditActive,
    checkedTicketIds,
    openBulkEditFlyout,
    setOnSuccessCallback: (callback: () => void) => {
      onSuccessCallback = callback
    },
    onSuccessCallback,
  }

  provide(TICKET_BULK_EDIT_SYMBOL, provideBulkEdit)

  return provideBulkEdit
}
