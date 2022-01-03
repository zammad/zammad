// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { onError } from '@apollo/client/link/error'
import getErrorContext from '@common/server/apollo/utils/getErrorContext'
import log from '@common/utils/log'
import {
  GraphQLErrorExtensionsHandler,
  GraphQLErrorTypes,
} from '@common/types/error'
import useSessionIdStore from '@common/stores/session/id'

const errorLink = onError(({ graphQLErrors, networkError, operation }) => {
  const errorContext = getErrorContext(operation)

  const errorMessages: Array<string> = []

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
        operation.operationName !== 'sessionId' &&
        type === GraphQLErrorTypes.NotAuthorized
      ) {
        // Reset sessionId after an unathenticated error type.
        useSessionIdStore().value = null

        log.warn('Session invalid, trigger logout and show login page.')
      }
    })
  }

  if (networkError) {
    errorMessages.push(`[Network error]: ${networkError}`)
  }

  if (errorContext.logLevel === 'silent') return

  log[errorContext.logLevel](...errorMessages)
})

export default errorLink
