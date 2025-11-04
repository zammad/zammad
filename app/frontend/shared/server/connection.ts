// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { differenceInMilliseconds } from 'date-fns'
import { computed, ref, watch } from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import {
  actionCableReopenDelay,
  checkWebSocketConnection,
  consumer,
  reopenWebSocketConnection,
} from '#shared/server/action_cable/consumer.ts'
import emitter from '#shared/utils/emitter.ts'
import log from '#shared/utils/log.ts'

import { getApolloClient } from './apollo/client.ts'

const TIMEOUT_TRIGGER_ERROR_MESSAGE = 7000

const wsConnectionState = ref(true)
const wsReopening = ref(false)

let connectionStoppedAt: Date | null = null

let failedConnectionTimeout: number | null = null
let triggerErrorMessageTimeout: number | null = null

const clearFailedConnectionTimeout = () => {
  if (failedConnectionTimeout) window.clearTimeout(failedConnectionTimeout)
  failedConnectionTimeout = null
}

const clearTriggerErrorMessageTimeout = () => {
  if (triggerErrorMessageTimeout) window.clearTimeout(triggerErrorMessageTimeout)
  triggerErrorMessageTimeout = null
}

useOnEmitter('websocket-open', () => {
  consumer.connection.reopenCalled = false

  if (!wsConnectionState.value && !wsReopening.value) {
    clearFailedConnectionTimeout()

    checkWebSocketConnection().then(() => {
      wsConnectionState.value = true
    })
  }
})

useOnEmitter('websocket-close', () => {
  if (!wsConnectionState.value || wsReopening.value) return

  clearFailedConnectionTimeout()

  // Wait until the reopen delay from action cable is over which is the case for the frist re-connect try
  // from the action cable connection monitor.
  if (consumer.connection.reopenCalled && !consumer.connection.triedToReconnect()) {
    failedConnectionTimeout = window.setTimeout(() => {
      wsConnectionState.value = false
    }, actionCableReopenDelay + 200)
  } else {
    wsConnectionState.value = false
  }
})

export const connected = computed(() => {
  return wsReopening.value || wsConnectionState.value
})

// Currently only some hardcoded queries are excluded, because the other things needs all to be reloaded:
// - Some are global queries.
// - And the other queries are still present because of the keep alive tab cache.
// The following queries are excluded:
// - `ticket` - because it's already returned via initial subscription call.
// - `detailSearch` / `searchCounts` - because it's refetched on navigation inside the search page.
// - 'ticketsCachedByOverview/userCurrentTicketOverviewsCount' - will be refetched with the next polling (and for foreground we have an own check).
const getExcludeQueries = () => {
  const queries = new Set<string>([
    'ticket',
    'ticketsCachedByOverview',
    'userCurrentTicketOverviewsCount',
    'detailSearch',
    'searchCounts',
  ])

  return queries
}

const getQueriesToRefetch = (): string[] => {
  const queriesToRefetch = new Set<string>()
  const excludeQueries = getExcludeQueries()

  getApolloClient()
    .getObservableQueries('active')
    .forEach((query) => {
      const { queryName } = query

      if (!queryName || excludeQueries.has(queryName)) return

      queriesToRefetch.add(queryName)
    })

  return Array.from(queriesToRefetch)
}

export const handleConnection = (
  connectionLostCallback: () => void,
  reconnectCallback: () => void,
  refetchMode: 'active' | 'specific' = 'specific',
): void => {
  watch(connected, (newValue) => {
    if (newValue) {
      log.debug('[ActionCable] Application websocket connection just came up.')

      // Not refetch everything, when connection was only stopped for a very short time.
      if (connectionStoppedAt && differenceInMilliseconds(new Date(), connectionStoppedAt) > 2000) {
        const apolloClient = getApolloClient()
        if (refetchMode === 'active') {
          apolloClient.reFetchObservableQueries()
        } else {
          apolloClient.refetchQueries({
            include: getQueriesToRefetch(),
          })
        }
      }

      connectionStoppedAt = null

      reconnectCallback()

      if (triggerErrorMessageTimeout) clearTriggerErrorMessageTimeout()

      emitter.emit('reconnected')
    } else {
      connectionStoppedAt = new Date()
      log.debug('[ActionCable] Application websocket connection just went down.')

      triggerErrorMessageTimeout = window.setTimeout(
        () => connectionLostCallback(),
        TIMEOUT_TRIGGER_ERROR_MESSAGE,
      )
    }
  })
}

export const triggerWebSocketReconnect = (): void => {
  wsReopening.value = true
  reopenWebSocketConnection()
    .then(() => {
      // Set this before setting wsReopening, otherwise it would be set later by the interval,
      //  causing false positives.
      wsConnectionState.value = true
    })
    .finally(() => {
      wsReopening.value = false
    })
}
