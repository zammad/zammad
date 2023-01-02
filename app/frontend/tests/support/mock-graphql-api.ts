// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-use-before-define */

import { NetworkStatus } from '@apollo/client/core'
import type { UserError } from '@shared/graphql/types'
import type { GraphQLErrorReport } from '@shared/types/error'
import type { DocumentNode } from 'graphql'
import {
  createMockSubscription,
  type IMockSubscription,
  type RequestHandlerResponse,
} from 'mock-apollo-client'
import type { SpyInstance } from 'vitest'
import createMockClient from './mock-apollo-client'
import { waitForNextTick } from './utils'

interface Result {
  [key: string]: unknown
}

interface ResultWithUserError extends Result {
  errors: UserError[]
}

type OperationResultWithUserError = Record<string, ResultWithUserError>

export interface MockGraphQLInstance {
  willBehave<T>(handler: (variables: any) => T): MockGraphQLInstance
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
    behave: SpyInstance
    resolve: SpyInstance
    error: SpyInstance
    userError: SpyInstance
    networkError: SpyInstance
  }
  calls: {
    behave: number
    resolve: number
    error: number
    userError: number
    networkError: number
  }
}

export const mockGraphQLApi = (
  operationDocument: DocumentNode,
): MockGraphQLInstance => {
  const resolveSpy = vi.fn()
  const errorSpy = vi.fn()
  const userErrorSpy = vi.fn()
  const networkErrorSpy = vi.fn()
  const behaveSpy = vi.fn()

  const willBehave = (fn: (variables: any) => unknown) => {
    behaveSpy.mockImplementation(async (variables: any) => fn(variables))
    createMockClient([
      {
        operationDocument,
        handler: behaveSpy,
      },
    ])
    return instance
  }

  const willResolve = <T>(result: T | T[]) => {
    if (Array.isArray(result)) {
      result.forEach((singleResult) => {
        resolveSpy.mockResolvedValueOnce({ data: singleResult })
      })
    } else {
      resolveSpy.mockResolvedValue({ data: result })
    }
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
    willBehave,
    spies: {
      behave: behaveSpy,
      resolve: resolveSpy,
      error: errorSpy,
      userError: userErrorSpy,
      networkError: networkErrorSpy,
    },
    calls: {
      get behave() {
        return behaveSpy.mock.calls.length
      },
      get resolve() {
        return resolveSpy.mock.calls.length
      },
      get error() {
        return errorSpy.mock.calls.length
      },
      get userError() {
        return userErrorSpy.mock.calls.length
      },
      get networkError() {
        return networkErrorSpy.mock.calls.length
      },
    },
  }

  return instance
}

export interface ExtendedIMockSubscription<T = unknown>
  extends Omit<IMockSubscription, 'next' | 'closed'> {
  closed: () => boolean
  next: (result: RequestHandlerResponse<T>) => Promise<void>
}

export const mockGraphQLSubscription = <T>(
  operationDocument: DocumentNode,
): ExtendedIMockSubscription<T> => {
  const mockSubscription = createMockSubscription({ disableLogging: true })

  createMockClient([
    {
      operationDocument,
      handler: () => mockSubscription,
    },
  ])

  return {
    next: async (
      value: Parameters<typeof mockSubscription.next>[0],
    ): Promise<void> => {
      mockSubscription.next(value)

      await waitForNextTick(true)
    },
    error: mockSubscription.error.bind(mockSubscription),
    complete: mockSubscription.complete.bind(mockSubscription),
    closed: () => mockSubscription.closed,
  }
}
