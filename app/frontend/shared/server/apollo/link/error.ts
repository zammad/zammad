// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { onError } from '@apollo/client/link/error'

import getErrorContext from '#shared/server/apollo/utils/getErrorContext.ts'
import { recordCommunicationFailure } from '#shared/server/connection.ts'
import type { GraphQLErrorExtensionsHandler } from '#shared/types/error.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import emitter from '#shared/utils/emitter.ts'
import log from '#shared/utils/log.ts'

const errorLink = onError(
  ({ graphQLErrors, networkError, operation, forward }) => {
    const errorContext = getErrorContext(operation)

    const errorMessages: Array<string> = []

    // If the error is an AbortError, ignore it and forward the operation to avoid communication failure
    if (networkError?.name === 'AbortError') return forward(operation)

    if (graphQLErrors) {
      graphQLErrors.forEach(({ message, extensions, path }) => {
        const { type, backtrace }: GraphQLErrorExtensionsHandler = {
          type:
            (extensions?.type as GraphQLErrorTypes) ||
            GraphQLErrorTypes.NetworkError,
          backtrace: extensions?.backtrace as string,
        }

        errorMessages.push(
          `[GraphQL error - ${type}]: ${message}, Path: ${path}`,
          backtrace,
        )

        if (
          operation.operationName !== 'session' &&
          type === GraphQLErrorTypes.NotAuthorized
        ) {
          // Reset authenticated state after an unathenticated error type.
          emitter.emit('sessionInvalid')

          log.warn('Session invalid, trigger logout and show login page.')
        }
      })
    }

    if (networkError) {
      // Suppress error message in Capybara test context, as it can happen if the
      //  test session is reset to 'about:blank' while requests are still running.
      if (!VITE_TEST_MODE)
        errorMessages.push(`[Network error]: ${networkError}`)
      // Network error implies application connection problems.
      // TODO: what's missing here is a detection of web socket disconnects.
      recordCommunicationFailure()
    }

    if (errorContext.logLevel === 'silent') return

    log[errorContext.logLevel](...errorMessages)
  },
)

export default errorLink
