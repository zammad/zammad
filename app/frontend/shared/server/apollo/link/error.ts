// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onError } from '@apollo/client/link/error'

import {
  authenticationGenerationOutdated,
  authenticationInvalidated,
} from '#shared/server/apollo/utils/authenticationState.ts'
import getErrorContext from '#shared/server/apollo/utils/getErrorContext.ts'
import type { GraphQLErrorExtensionsHandler } from '#shared/types/error.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import emitter from '#shared/utils/emitter.ts'
import log from '#shared/utils/log.ts'

const errorLink = onError(({ graphQLErrors, networkError, operation }) => {
  const errorContext = getErrorContext(operation)

  const errorMessages: Array<string> = []

  // If the error is an AbortError, ignore it and forward the operation to avoid communication failure
  if (networkError?.name === 'AbortError') return

  if (graphQLErrors) {
    graphQLErrors.forEach(({ message, extensions, path }) => {
      const { type, backtrace }: GraphQLErrorExtensionsHandler = {
        type: (extensions?.type as GraphQLErrorTypes) || GraphQLErrorTypes.NetworkError,
        backtrace: extensions?.backtrace as string,
      }

      const errorMessage = `[GraphQL error - ${type}]: ${message}, Path: ${path}`

      if (operation.operationName !== 'session' && type === GraphQLErrorTypes.NotAuthorized) {
        // An operation which was left over from the authenticated app can still
        //  fail after the authentication was invalidated. That is expected, so
        //  only mention it for debugging and don't invalidate the session again.
        if (authenticationInvalidated()) {
          log.debug(`${errorMessage} (expected, the authentication is already gone)`)
          return
        }

        // The same operation can also come back only after a new login already
        //  happened. It must not invalidate the session it does not belong to.
        if (authenticationGenerationOutdated(operation)) {
          log.debug(`${errorMessage} (expected, it belongs to a previous authentication)`)
          return
        }

        // Reset authenticated state after an unathenticated error type.
        emitter.emit('session-invalid')

        log.warn('Session invalid, trigger logout and show login page.')
      }

      errorMessages.push(errorMessage, backtrace)
    })
  }

  if (networkError) {
    // Suppress error message in Capybara test context, as it can happen if the
    //  test session is reset to 'about:blank' while requests are still running.
    if (!VITE_TEST_MODE) {
      errorMessages.push(`[Network error]: ${networkError}`)
    }
  }

  if (!errorMessages.length || errorContext.logLevel === 'silent') return

  log[errorContext.logLevel](...errorMessages)
})

export default errorLink
