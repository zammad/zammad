// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, watch } from 'vue'
import consumer from '@shared/server/action_cable/consumer'
import log from '@shared/utils/log'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { useApplicationLoaded } from '@shared/composables/useApplicationLoaded'

const wsConnectionState = ref(true)
const { loaded } = useApplicationLoaded()

window.setInterval(() => {
  wsConnectionState.value = !loaded.value || consumer.connection.isOpen()
}, 1000)

let connectionNotificationId: string
const networkConnectionState = ref(true)
const connected = computed(() => {
  return wsConnectionState.value && networkConnectionState.value
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
