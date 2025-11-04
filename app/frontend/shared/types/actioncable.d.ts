// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

// Extend ActionCable types globally.
declare global {
  namespace ActionCable {
    interface Connection {
      events: {
        open: () => void
        close: () => void
        error: () => void
      }
      triedToReconnect: () => boolean
      reopenCalled: boolean
    }
  }
}

export {}
