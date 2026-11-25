// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { consumer } from '../consumer.ts'

describe('consumer', () => {
  it('registers global helpers to disconnect and reconnect the websocket', () => {
    const disconnect = vi.spyOn(consumer, 'disconnect').mockImplementation(() => {})
    const connect = vi.spyOn(consumer, 'connect').mockImplementation(() => true)

    window.disconnectWebSocket()

    expect(disconnect).toHaveBeenCalledOnce()
    expect(connect).not.toHaveBeenCalled()

    window.reconnectWebSocket()

    expect(connect).toHaveBeenCalledOnce()
  })
})
