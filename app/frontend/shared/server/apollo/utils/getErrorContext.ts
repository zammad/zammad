// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Operation } from '@apollo/client/core'
import type { ClientErrorContext } from '@shared/types/server/apollo/client'

export default function getErrorContext(
  operation: Operation,
): ClientErrorContext {
  const defaultErrorContext: ClientErrorContext = {
    logLevel: 'error',
  }
  const context = operation.getContext()
  const error: Partial<ClientErrorContext> = context.error || {}

  return Object.assign(defaultErrorContext, error)
}
