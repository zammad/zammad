// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import * as ActionCable from '@rails/actioncable'

import log from '#shared/utils/log.ts'

ActionCable.adapters.logger = log as unknown as Console
ActionCable.logger.enabled = true

export const consumer = ActionCable.createConsumer()

export const reopenWebSocketConnection = () => {
  consumer.connection.reopen()
  return new Promise<void>((resolve, reject) => {
    const startTime = Date.now()

    const checkConnection = () => {
      if (consumer.connection.isOpen()) {
        resolve()
      }
      // to avoid infinite loop
      else if (Date.now() - startTime > 10_000) {
        reject(new Error('failed to reconnect'))
      } else {
        setTimeout(checkConnection, 100)
      }
    }

    checkConnection()
  })
}
