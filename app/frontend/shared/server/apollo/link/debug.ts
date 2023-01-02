// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { capitalize, isEmpty } from 'lodash-es'
import { ApolloLink } from '@apollo/client/core'
import { getMainDefinition } from '@apollo/client/utilities'
import { print } from 'graphql/language/printer'
import type {
  DebugLinkRequestOutput,
  DebugLinkResponseOutput,
} from '@shared/types/server/apollo/client'
import log from '@shared/utils/log'

const debugLink = new ApolloLink((operation, forward) => {
  if (log.getLevel() < log.levels.DEBUG) return forward(operation)

  const requestContext = operation.getContext()

  const definition = getMainDefinition(operation.query)
  const opeationType =
    definition.kind === 'OperationDefinition'
      ? capitalize(definition.operation)
      : null

  const requestOutput: DebugLinkRequestOutput = {
    printedDocument: print(operation.query),
    document: operation.query,
  }

  if (!isEmpty(operation.variables)) {
    requestOutput.variables = operation.variables
  }

  if (!isEmpty(requestContext.headers)) {
    requestOutput.requestHeaders = requestContext.headers
  }

  // Called before operation is sent to server
  operation.setContext({ start: new Date() })

  log.debug(
    `[GraphQL - Request] - ${opeationType} - ${operation.operationName}:`,
    requestOutput,
  )

  return forward(operation).map((data) => {
    const context = operation.getContext()
    const end = new Date()

    const responseHeaders: Record<string, string> = {}
    if (context?.response?.headers) {
      context.response.headers.forEach((value: string, key: string) => {
        responseHeaders[key] = value
      })
    }

    const duration = end.getTime() - context.start.getTime()

    const responseOutput: DebugLinkResponseOutput = {
      data,
    }

    if (!isEmpty(responseHeaders)) {
      responseOutput.responseHeaders = responseHeaders
    }

    log.debug(
      `[GraphQL - Response] - ${opeationType} - ${operation.operationName} (took ${duration}ms):`,
      responseOutput,
    )
    return data
  })
})

export default debugLink
