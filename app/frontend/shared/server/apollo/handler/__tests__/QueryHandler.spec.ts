// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { NetworkStatus } from '@apollo/client/core'
import { useLazyQuery, useQuery } from '@vue/apollo-composable'
import { createMockSubscription } from 'mock-apollo-client'
import { effectScope } from 'vue'

import {
  SampleTypedQueryDocument,
  SampleTypedSubscriptionDocument,
} from '#tests/fixtures/graphqlSampleTypes.ts'
import type {
  SampleQuery,
  SampleQueryVariables,
  SampleUpdatedSubscriptionVariables,
} from '#tests/fixtures/graphqlSampleTypes.ts'
import createMockClient from '#tests/support/mock-apollo-client.ts'
import { waitForNextTick, waitUntilSpyCalled } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import QueryHandler from '../QueryHandler.ts'

import type { ApolloError, ApolloQueryResult } from '@apollo/client/core'
import type { IMockSubscription } from 'mock-apollo-client'

const queryFunctionCallSpy = vi.fn()

const querySampleResult = {
  Sample: {
    __typename: 'Sample',
    id: 1,
    title: 'Test Title',
    text: 'Test Text',
  },
}

const querySampleErrorResult = {
  networkStatus: NetworkStatus.error,
  errors: [
    {
      message: 'GraphQL Error',
      extensions: { type: 'Exceptions::UnknownError' },
    },
  ],
}

const querySampleNotAuthorizedErrorResult = {
  networkStatus: NetworkStatus.error,
  errors: [
    {
      message: 'Authentication required',
      extensions: { type: 'Exceptions::NotAuthorized' },
    },
  ],
}

const querySampleNetworkErrorResult = new Error('GraphQL Network Error')

const handlerCallSpy = vi.fn()

const mockClient = (error = false, errorType = 'GraphQL') => {
  handlerCallSpy.mockImplementation(() => {
    if (error) {
      return errorType === 'GraphQL'
        ? Promise.resolve(querySampleErrorResult)
        : Promise.reject(querySampleNetworkErrorResult)
    }

    return Promise.resolve({
      data: querySampleResult,
    })
  })

  createMockClient([
    {
      operationDocument: SampleTypedQueryDocument,
      handler: handlerCallSpy,
    },
  ])

  handlerCallSpy.mockClear()
  queryFunctionCallSpy.mockClear()
}

const waitFirstResult = (queryHandler: QueryHandler<any, any>) =>
  new Promise<ApolloQueryResult<any> | ApolloError>((resolve) => {
    queryHandler.onResult((res) => {
      if (res.data) {
        resolve(res)
      }
    })
    queryHandler.onError((err) => {
      resolve(err)
    })
  })

describe('QueryHandler', () => {
  const sampleQuery = (variables: SampleQueryVariables, options = {}) => {
    queryFunctionCallSpy()

    const query = useQuery<SampleQuery, SampleQueryVariables>(
      SampleTypedQueryDocument,
      variables,
      options,
    )

    return query
  }

  const sampleLazyQuery = (variables: SampleQueryVariables, options = {}) => {
    queryFunctionCallSpy()
    return useLazyQuery<SampleQuery, SampleQueryVariables>(
      SampleTypedQueryDocument,
      variables,
      options,
    )
  }

  const scope = effectScope()

  describe('constructor', () => {
    beforeEach(() => {
      mockClient()
    })

    it('instance can be created', () => {
      scope.run(() => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
        expect(queryHandlerObject).toBeInstanceOf(QueryHandler)
      })
    })
    it('default handler options can be changed', () => {
      scope.run(() => {
        const errorNotificationMessage = 'A test message.'

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
          errorNotificationMessage,
        })
        expect(queryHandlerObject.handlerOptions.errorNotificationMessage).toBe(
          errorNotificationMessage,
        )
      })
    })

    it('given query function was executed', () => {
      scope.run(() => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
        expect(queryFunctionCallSpy).toBeCalled()
        expect(queryHandlerObject.operationResult).toBeTruthy()
      })
    })
  })

  describe('loading', () => {
    beforeEach(() => {
      mockClient()
    })

    it('loading state will be updated', async () => {
      await scope.run(async () => {
        expect.assertions(2)

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
        const loading = queryHandlerObject.loading()
        expect(loading.value).toBe(true)

        await waitFirstResult(queryHandlerObject)

        expect(loading.value).toBe(false)
      })
    })

    it('supports lazy queries', async () => {
      await scope.run(async () => {
        expect.assertions(3)

        const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

        expect(queryHandlerObject.loading().value).toBe(false)

        queryHandlerObject.load()
        await waitForNextTick()

        expect(queryHandlerObject.loading().value).toBe(true)

        await queryHandlerObject.query()

        expect(queryHandlerObject.loading().value).toBe(false)
      })
    })
  })

  describe('result', () => {
    beforeEach(() => {
      mockClient()
    })

    it('result is available', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        const result = await waitFirstResult(queryHandlerObject)

        expect(result).toMatchObject({
          data: querySampleResult,
        })
      })
    })

    it('loaded() resolves once the query has settled', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        await expect(queryHandlerObject.loaded()).resolves.toBeUndefined()

        expect(queryHandlerObject.result().value).toEqual(querySampleResult)
      })
    })

    it('loaded result is also resolved after additional result call with active trigger refetch', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

        await expect(queryHandlerObject.query()).resolves.toMatchObject({
          data: querySampleResult,
        })

        await expect(queryHandlerObject.query()).resolves.toMatchObject({
          data: querySampleResult,
        })

        expect(handlerCallSpy).toBeCalledTimes(1)
      })
    })

    it('watch on result change', async () => {
      await scope.run(async () => {
        expect.assertions(1)

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        queryHandlerObject.watchOnResult((result) => {
          expect(result).toEqual(querySampleResult)
        })
        await waitFirstResult(queryHandlerObject)
      })
    })

    it('registers and unregisters an onResult callback', async () => {
      await scope.run(async () => {
        expect.assertions(2)

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
        const resultCallbackSpy = vi.fn()

        const { off } = queryHandlerObject.onResult((result) => resultCallbackSpy(result))

        await waitFirstResult(queryHandlerObject)

        expect(resultCallbackSpy).toHaveBeenCalledWith(
          expect.objectContaining({ data: querySampleResult }),
        )

        const callbackCountBeforeOff = resultCallbackSpy.mock.calls.length

        off()
        await queryHandlerObject.refetch()
        await waitForNextTick()

        expect(resultCallbackSpy).toHaveBeenCalledTimes(callbackCountBeforeOff)
      })
    })

    it('receive value immediately in non-reactive way', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

        await expect(queryHandlerObject.query()).resolves.toEqual(
          expect.objectContaining({ data: querySampleResult }),
        )
      })
    })

    it('cancels previous attempt, if the new one started', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

        const cancelSpy = vi.spyOn(queryHandlerObject, 'cancel')

        expect(cancelSpy).not.toHaveBeenCalled()

        const result1 = queryHandlerObject.query()

        expect(cancelSpy).toHaveBeenCalledTimes(1)

        const result2 = queryHandlerObject.query()

        expect(cancelSpy).toHaveBeenCalledTimes(2)

        // both resolve, because signal is not actually aborted in node
        await expect(result1).resolves.toEqual(expect.objectContaining({ data: querySampleResult }))
        await expect(result2).resolves.toEqual(expect.objectContaining({ data: querySampleResult }))
      })
    })
  })

  describe('error handling', () => {
    describe('GraphQL errors', () => {
      beforeEach(() => {
        mockClient(true)
      })

      it('notification is triggerd', async () => {
        await scope.run(async () => {
          expect.assertions(1)

          const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

          await waitFirstResult(queryHandlerObject)

          const { notifications } = useNotifications()

          expect(notifications.value.length).toBe(1)
        })
      })

      it('loaded() resolves even when the query errors', async () => {
        await scope.run(async () => {
          const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

          await expect(queryHandlerObject.loaded()).resolves.toBeUndefined()
        })
      })

      it('use error callback', async () => {
        await scope.run(async () => {
          expect.assertions(1)

          const errorCallbackSpy = vi.fn()

          const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
            errorCallback: (error) => {
              errorCallbackSpy(error)
            },
          })

          await waitFirstResult(queryHandlerObject)
          await waitUntilSpyCalled(errorCallbackSpy)

          expect(errorCallbackSpy).toHaveBeenCalledWith({
            type: 'Exceptions::UnknownError',
            message: 'GraphQL Error',
          })
        })
      })

      it('refetch with error', async () => {
        await scope.run(async () => {
          expect.assertions(1)
          const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

          const errorCallbackSpy = vi.fn()

          await waitFirstResult(queryHandlerObject)

          // Refetch after first load again.
          await queryHandlerObject.refetch().catch((error) => {
            errorCallbackSpy(error)
          })

          expect(errorCallbackSpy).toHaveBeenCalled()
        })
      })
    })

    describe('Network errors', () => {
      beforeEach(() => {
        mockClient(true, 'NetworkError')
      })

      it('use error callback', async () => {
        await scope.run(async () => {
          expect.assertions(1)
          const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
            errorCallback: (error) => {
              expect(error).toEqual({
                type: GraphQLErrorTypes.NetworkError,
              })
            },
          })

          await waitFirstResult(queryHandlerObject)
        })
      })
    })
  })

  describe('use operation result wrapper', () => {
    beforeEach(() => {
      mockClient()
    })

    it('use returned query options', () => {
      scope.run(() => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        expect(queryHandlerObject.options()).toBeTruthy()
      })
    })

    it('use fetchMore query function', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        await expect(queryHandlerObject.fetchMore({})).resolves.toEqual(querySampleResult)
      })
    })
  })

  describe('subscribeToMore', () => {
    let mockSubscription: IMockSubscription

    // Every example gets its own scope, so that the subscription of one does not
    //  receive the error of the next one.
    let subscriptionScope: ReturnType<typeof effectScope>

    // Apollo only logs an unhandled subscription error when its development
    //  diagnostics are on, which the test setup switches off globally. Turn them
    //  on for the error itself only - a client constructed with them on would
    //  schedule the devtools suggestion timer (see 'tests/vitest.setup.ts').
    const withDevelopmentDiagnostics = (emitError: () => void) => {
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      ;(globalThis as any).__DEV__ = true

      try {
        emitError()
      } finally {
        ;(globalThis as any).__DEV__ = false
      }

      return consoleErrorSpy
    }

    // The examples of this file share one notification store, so only the
    //  notifications of the current example can be counted.
    const countNewNotifications = () => {
      const { notifications } = useNotifications()
      const before = notifications.value.length

      return () => notifications.value.length - before
    }

    const subscribeToMoreOptions = (options = {}) => ({
      document: SampleTypedSubscriptionDocument,
      variables: { id: 1 },
      ...options,
    })

    beforeEach(() => {
      mockSubscription = createMockSubscription()

      mockClient()

      createMockClient([
        {
          operationDocument: SampleTypedSubscriptionDocument,
          handler: () => mockSubscription,
        },
      ])

      subscriptionScope = effectScope()
    })

    afterEach(() => {
      subscriptionScope.stop()

      vi.mocked(console.error).mockReset()
    })

    it('stays quiet about an authentication error', () => {
      subscriptionScope.run(() => {
        const errorCallbackSpy = vi.fn()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(
          subscribeToMoreOptions(),
        )

        const newNotifications = countNewNotifications()

        const consoleErrorSpy = withDevelopmentDiagnostics(() =>
          mockSubscription.next(querySampleNotAuthorizedErrorResult),
        )

        expect(consoleErrorSpy).not.toHaveBeenCalled()
        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: GraphQLErrorTypes.NotAuthorized,
          message: 'Authentication required',
        })
        expect(newNotifications()).toBe(0)
      })
    })

    it('reports any other error through the handler', () => {
      subscriptionScope.run(() => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(
          subscribeToMoreOptions(),
        )

        const newNotifications = countNewNotifications()

        const consoleErrorSpy = withDevelopmentDiagnostics(() =>
          mockSubscription.next(querySampleErrorResult),
        )

        expect(consoleErrorSpy).not.toHaveBeenCalled()
        expect(newNotifications()).toBe(1)
      })
    })

    it('reports a plain network error through the handler', () => {
      subscriptionScope.run(() => {
        const errorCallbackSpy = vi.fn()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(
          subscribeToMoreOptions(),
        )

        const consoleErrorSpy = withDevelopmentDiagnostics(() =>
          mockSubscription.error(querySampleNetworkErrorResult),
        )

        expect(consoleErrorSpy).not.toHaveBeenCalled()
        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: GraphQLErrorTypes.NetworkError,
        })
      })
    })

    it('keeps an explicitly given error callback', () => {
      subscriptionScope.run(() => {
        const onErrorSpy = vi.fn()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(
          subscribeToMoreOptions({ onError: onErrorSpy }),
        )

        const newNotifications = countNewNotifications()

        const consoleErrorSpy = withDevelopmentDiagnostics(() =>
          mockSubscription.next(querySampleErrorResult),
        )

        expect(consoleErrorSpy).not.toHaveBeenCalled()
        expect(onErrorSpy).toHaveBeenCalled()
        expect(newNotifications()).toBe(0)
      })
    })

    it('handles the error of reactive options', () => {
      subscriptionScope.run(() => {
        const errorCallbackSpy = vi.fn()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(() =>
          subscribeToMoreOptions(),
        )

        const newNotifications = countNewNotifications()

        const consoleErrorSpy = withDevelopmentDiagnostics(() =>
          mockSubscription.next(querySampleNotAuthorizedErrorResult),
        )

        expect(consoleErrorSpy).not.toHaveBeenCalled()
        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: GraphQLErrorTypes.NotAuthorized,
          message: 'Authentication required',
        })
        expect(newNotifications()).toBe(0)
      })
    })
  })
})
