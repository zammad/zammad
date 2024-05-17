// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useApplicationLoaded } from '#shared/composables/useApplicationLoaded.ts'
import {
  consumer,
  reopenWebSocketConnection,
} from '#shared/server/action_cable/consumer.ts'
import log from '#shared/utils/log.ts'

const wsConnectionState = ref(true)
const wsReopening = ref(false)
const { loaded } = useApplicationLoaded()

const isConnectionOpen = () => !loaded.value || consumer.connection.isOpen()

const INTERVAL_CHECK_CONNECTION = 1000
const TIMEOUT_CONFIRM_FAIL = 2000

let faledTimeout: number | null = null
let checkInterval: number | null = null

const clearFailedTimeout = () => {
  if (faledTimeout) window.clearTimeout(faledTimeout)
  faledTimeout = null
}

const clearCheckInterval = () => {
  if (checkInterval) window.clearInterval(checkInterval)
  checkInterval = null
}

const checkStatus = () => {
  clearCheckInterval()

  checkInterval = window.setInterval(() => {
    const hasConnection = isConnectionOpen()

    if (hasConnection) {
      wsConnectionState.value = true
      return
    }

    // if there is no connection, let's wait a few seconds and check again
    // pause interval while we wait

    clearCheckInterval()
    clearFailedTimeout()
    faledTimeout = window.setTimeout(() => {
      wsConnectionState.value = isConnectionOpen()
      checkStatus()
    }, TIMEOUT_CONFIRM_FAIL)
  }, INTERVAL_CHECK_CONNECTION)
}

checkStatus()

let connectionNotificationId: string
const networkConnectionState = ref(true)
const connected = computed(() => {
  return (
    (wsReopening.value || wsConnectionState.value) &&
    networkConnectionState.value
  )
})

const notifications = useNotifications()

watch(
  () => connected.value,
  (connected) => {
    if (connected) {
      if (!connectionNotificationId) return
      log.debug('Application connection just came up.')
      notifications.removeNotification(connectionNotificationId)
    } else {
      log.debug('Application connection just went down.')
      connectionNotificationId = notifications.notify({
        id: 'connection-lost',
        message: __('The connection to the server was lost.'),
        type: NotificationTypes.Error,
        persistent: true,
      })
    }
  },
)

export const recordCommunicationSuccess = (): void => {
  networkConnectionState.value = true
}

export const recordCommunicationFailure = (): void => {
  networkConnectionState.value = false
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
