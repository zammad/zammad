// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { Operation } from '@apollo/client/core'
import { ClientErrorContext } from '@common/types/server/apollo/client'

const defaultErrorContext: ClientErrorContext = {
  logLevel: 'error',
}

export default function getErrorContext(
  operation: Operation,
): ClientErrorContext {
  const context = operation.getContext()
  const error: Partial<ClientErrorContext> = context.error || {}

  return Object.assign(defaultErrorContext, error)
}
