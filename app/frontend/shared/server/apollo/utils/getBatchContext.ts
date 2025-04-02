// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ClientBatchContext } from '#shared/types/server/apollo/client.ts'

import type { Operation } from '@apollo/client/core'

export default function getBatchContext(
  operation: Operation,
): ClientBatchContext {
  const defaultBatchContext: ClientBatchContext = {
    active: true,
  }
  const context = operation.getContext()
  const batch: Partial<ClientBatchContext> = context.batch || {}

  return Object.assign(defaultBatchContext, batch)
}
