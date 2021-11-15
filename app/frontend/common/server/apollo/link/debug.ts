// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'
import log from '@common/utils/log'

const debugLink = new ApolloLink((operation, forward) => {
  if (log.getLevel() < log.levels.DEBUG) return forward(operation)

  // TODO: add maybe also a time tracking for request->response time.

  // Called before operation is sent to server
  // operation.setContext({ start: new Date() })
  log.debug(
    `[GraphQL - Request] - ${operation.operationName}:`,
    operation.getContext(),
  )

  return forward(operation).map((data) => {
    // Called after server responds
    // const end = new Date()

    // const time = end - operation.getContext().start
    log.debug(
      `[GraphQL - Response] - ${operation.operationName}:`,
      operation.getContext(),
    )
    return data
  })
})

export default debugLink
