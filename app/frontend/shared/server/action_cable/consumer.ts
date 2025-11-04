// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import * as ActionCable from '@rails/actioncable'

import emitter from '#shared/utils/emitter.ts'
import log from '#shared/utils/log.ts'

ActionCable.adapters.logger = log as unknown as Console
ActionCable.logger.enabled = true

export const consumer = ActionCable.createConsumer()

// We can't modify reconnectionBackoffRate directly since it's read-only.
// We want to have a stable reconnection time so we set this backoff rate to 0.
Object.defineProperty(ActionCable.ConnectionMonitor, 'reconnectionBackoffRate', {
  value: 0,
  writable: true,
})

const originalOpen = ActionCable.Connection.prototype.events.open
ActionCable.Connection.prototype.events.open = () => {
  emitter.emit('websocket-open')

  originalOpen.call(consumer.connection)
}

const originalClose = ActionCable.Connection.prototype.events.close
ActionCable.Connection.prototype.events.close = () => {
  emitter.emit('websocket-close')
  originalClose.call(consumer.connection)
}

const originalReopen = ActionCable.Connection.prototype.reopen
ActionCable.Connection.prototype.reopen = () => {
  consumer.connection.reopenCalled = true

  originalReopen.call(consumer.connection)
}

export const actionCableReopenDelay = ActionCable.Connection.reopenDelay

export const checkWebSocketConnection = () => {
  return new Promise<void>((resolve, reject) => {
    const startTime = Date.now()

    const checkConnection = () => {
      if (consumer.connection.isOpen()) {
        resolve()
      }

      // To avoid the infinite loop.
      else if (Date.now() - startTime > 5000) {
        reject(new Error('failed to reconnect'))
      } else {
        setTimeout(checkConnection, 100)
      }
    }

    checkConnection()
  })
}

export const reopenWebSocketConnection = () => {
  consumer.connection.reopen()

  return checkWebSocketConnection()
}
