// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ClientWebsocketContext } from '#shared/types/server/apollo/client.ts'

import type { Operation } from '@apollo/client/core'

export default function getBatchContext(
  operation: Operation,
): ClientWebsocketContext {
  const defaultWebsocketContext: ClientWebsocketContext = {
    active: false,
  }
  const context = operation.getContext()
  const websocket: Partial<ClientWebsocketContext> = context.websocket || {}

  return Object.assign(defaultWebsocketContext, websocket)
}
