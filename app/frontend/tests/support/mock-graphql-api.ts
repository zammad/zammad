// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-use-before-define */

import { NetworkStatus } from '@apollo/client/core'
import type { UserError } from '@shared/graphql/types'
import { GraphQLErrorReport } from '@shared/types/error'
import type { DocumentNode } from 'graphql'
import { createMockSubscription } from 'mock-apollo-client'
import type { SpyInstance } from 'vitest'
import createMockClient from './mock-apollo-client'

interface Result {
  [key: string]: unknown
}

interface ResultWithUserError extends Result {
  errors: UserError[]
}

type OperationResultWithUserError = Record<string, ResultWithUserError>

export interface MockGraphQLInstance {
  willResolve<T>(result: T): MockGraphQLInstance
  willFailWithError(
    errors: GraphQLErrorReport[],
    networkStatus?: NetworkStatus,
  ): MockGraphQLInstance
  willFailWithUserError(
    result: OperationResultWithUserError,
  ): MockGraphQLInstance
  willFailWithNetworkError(error: Error): MockGraphQLInstance
  spies: {
    resolve: SpyInstance
    error: SpyInstance
    userError: SpyInstance
    networkError: SpyInstance
  }
}

export const mockGraphQLApi = (
  operationDocument: DocumentNode,
): MockGraphQLInstance => {
  const resolveSpy = vi.fn()
  const errorSpy = vi.fn()
  const userErrorSpy = vi.fn()
  const networkErrorSpy = vi.fn()

  const willResolve = <T>(result: T) => {
    resolveSpy.mockResolvedValue({ data: result })
    createMockClient([
      {
        operationDocument,
        handler: resolveSpy,
      },
    ])
    return instance
  }

  const willFailWithError = (
    errors: GraphQLErrorReport[],
    networkStatus?: NetworkStatus,
  ) => {
    errorSpy.mockResolvedValue({
      networkStatus: networkStatus || NetworkStatus.error,
      errors,
    })
    createMockClient([
      {
        operationDocument,
        handler: errorSpy,
      },
    ])
    return instance
  }

  const willFailWithUserError = (result: OperationResultWithUserError) => {
    userErrorSpy.mockResolvedValue({ data: result })
    createMockClient([
      {
        operationDocument,
        handler: userErrorSpy,
      },
    ])
    return instance
  }

  const willFailWithNetworkError = (error: Error) => {
    networkErrorSpy.mockRejectedValue(error)
    createMockClient([
      {
        operationDocument,
        handler: networkErrorSpy,
      },
    ])
    return instance
  }

  const instance = {
    willFailWithError,
    willFailWithUserError,
    willFailWithNetworkError,
    willResolve,
    spies: {
      resolve: resolveSpy,
      error: errorSpy,
      userError: userErrorSpy,
      networkError: networkErrorSpy,
    },
  }

  return instance
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
