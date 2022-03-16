// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useNotifications from '@common/composables/useNotifications'
import { NotificationTypes } from '@common/types/notification'
import type { SingleValueStore } from '@common/types/store'
import log from 'loglevel'
import { defineStore } from 'pinia'

let notificationId: string

const notifications = useNotifications()

// TODO: consider switching from notification to a modal dialog, and improving the message
const useApplicationConnectedStore = defineStore('applicationConnected', {
  state: (): SingleValueStore<boolean> => {
    return {
      value: false,
    }
  },
  actions: {
    bringUp(): void {
      if (this.value) return
      log.debug('Application connection just came up.')
      if (notificationId) {
        notifications.removeNotification(notificationId)
      }
      this.value = true
    },
    takeDown(): void {
      if (!this.value) return
      log.debug('Application connection just went down.')
      notificationId = notifications.notify({
        message: __('The connection to the server was lost.'),
        type: NotificationTypes.ERROR,
        persistent: true,
      })
      this.value = false
    },
  },
})

export default useApplicationConnectedStore
