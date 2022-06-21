// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { NetworkStatus } from '@apollo/client/core'
import type { UserError } from '@shared/graphql/types'
import { GraphQLErrorReport } from '@shared/types/error'
import type { DocumentNode } from 'graphql'
import { createMockSubscription } from 'mock-apollo-client'
import createMockClient from './mock-apollo-client'

interface Result {
  [key: string]: unknown
}

interface ResultWithUserError extends Result {
  errors: UserError[]
}

type OperationResult = Record<string, Result | Array<unknown>>
type OperationResultWithUserError = Record<string, ResultWithUserError>

export const mockGraphQLApi = (operationDocument: DocumentNode) => {
  const willResolve = (result: OperationResult) => {
    createMockClient([
      {
        operationDocument,
        handler: () => {
          return Promise.resolve({
            data: result,
          })
        },
      },
    ])
  }

  const willFailWithError = (
    errors: GraphQLErrorReport[],
    networkStatus?: NetworkStatus,
  ) => {
    createMockClient([
      {
        operationDocument,
        handler: () => {
          return Promise.resolve({
            networkStatus: networkStatus || NetworkStatus.error,
            errors,
          })
        },
      },
    ])
  }

  const willFailWithUserError = (result: OperationResultWithUserError) => {
    createMockClient([
      {
        operationDocument,
        handler: () => {
          return Promise.resolve({
            data: result,
          })
        },
      },
    ])
  }

  const willFailWithNetworkError = (error: Error) => {
    createMockClient([
      {
        operationDocument,
        handler: () => {
          return Promise.reject(error)
        },
      },
    ])
  }

  return {
    willFailWithError,
    willFailWithUserError,
    willFailWithNetworkError,
    willResolve,
  }
}

export const mockGraphQLSubscription = (operationDocument: DocumentNode) => {
  const mockSubscription = createMockSubscription()

  createMockClient([
    {
      operationDocument,
      handler: () => mockSubscription,
    },
  ])

  return mockSubscription
}
