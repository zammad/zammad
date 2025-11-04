// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

declare module '@rails/actioncable' {
  export interface Connection {
    events: {
      open: () => void
      close: () => void
    }
    reopen: () => void
    reopenCalled?: boolean
    isOpen: () => boolean
    triedToReconnect: () => boolean
  }

  export interface ConnectionMonitor {
    reconnectionBackoffRate: number
  }

  export interface Consumer {
    connection: Connection
  }

  export const Connection: {
    prototype: Connection
    reopenDelay: number
  }

  export const ConnectionMonitor: ConnectionMonitor

  export const createConsumer: () => Consumer

  export const adapters: { logger: Console }
  export const logger: { enabled: boolean }
}
