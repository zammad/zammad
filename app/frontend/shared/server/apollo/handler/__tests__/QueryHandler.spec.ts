// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloClient, ApolloLink, InMemoryCache, NetworkStatus } from '@apollo/client'
import { relayStylePagination } from '@apollo/client/utilities'
import { provideApolloClient, useLazyQuery, useQuery } from '@vue/apollo-composable/compat'
import gql from 'graphql-tag'
import { createMockSubscription } from 'mock-apollo-client'
import { Observable } from 'rxjs'
import { onTestFinished } from 'vitest'
import { effectScope, ref } from 'vue'

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

import type { ErrorLike } from '@apollo/client'
import type { ApolloQueryResultV4 } from '@vue/apollo-composable/compat'
import type { IMockSubscription } from 'mock-apollo-client'
import type { Mock } from 'vitest'

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
  new Promise<ApolloQueryResultV4<any> | ErrorLike>((resolve) => {
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
        expect.assertions(4)

        const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

        expect(queryHandlerObject.loading().value).toBe(false)

        handlerCallSpy.mockImplementationOnce(
          () =>
            new Promise((resolve) => {
              setTimeout(() => resolve({ data: querySampleResult }), 10)
            }),
        )

        queryHandlerObject.load()
        await waitForNextTick()

        expect(queryHandlerObject.loading().value).toBe(true)

        await vi.waitFor(() => expect(queryHandlerObject.loading().value).toBe(false))
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

    it('does not call the onResult callback when a refetch fails', async () => {
      onTestFinished(() => useNotifications().clearAllNotifications())

      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
        const resultCallbackSpy = vi.fn()

        queryHandlerObject.onResult((result) => resultCallbackSpy(result))

        await waitFirstResult(queryHandlerObject)

        expect(resultCallbackSpy).toHaveBeenCalledTimes(1)

        handlerCallSpy.mockImplementation(() => Promise.resolve(querySampleErrorResult))

        await queryHandlerObject.refetch()
        await waitForNextTick()

        expect(resultCallbackSpy).toHaveBeenCalledTimes(1)
        expect(queryHandlerObject.operationError().value).toBeTruthy()
      })
    })

    it('does not call the onResult callback before the first data arrives', async () => {
      await scope.run(async () => {
        handlerCallSpy.mockImplementationOnce(
          () =>
            new Promise((resolve) => {
              setTimeout(() => resolve({ data: querySampleResult }), 10)
            }),
        )

        const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))
        const resultCallbackSpy = vi.fn()

        queryHandlerObject.onResult((result) => resultCallbackSpy(result))

        queryHandlerObject.load()
        await waitForNextTick()

        expect(queryHandlerObject.loading().value).toBe(true)
        expect(resultCallbackSpy).not.toHaveBeenCalled()

        await vi.waitFor(() => expect(resultCallbackSpy).toHaveBeenCalledTimes(1))
      })
    })

    it('does not repeat the previous result while a refetch is loading', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
        const resultCallbackSpy = vi.fn()

        queryHandlerObject.onResult((result) => resultCallbackSpy(result))

        await waitFirstResult(queryHandlerObject)

        expect(resultCallbackSpy).toHaveBeenCalledTimes(1)

        const refetchedSampleResult = {
          Sample: { ...querySampleResult.Sample, title: 'Refetched Title' },
        }

        handlerCallSpy.mockImplementationOnce(
          () =>
            new Promise((resolve) => {
              setTimeout(() => resolve({ data: refetchedSampleResult }), 10)
            }),
        )

        const refetch = queryHandlerObject.refetch()
        await waitForNextTick()

        expect(queryHandlerObject.loading().value).toBe(true)
        expect(resultCallbackSpy).toHaveBeenCalledTimes(1)

        await refetch
        await waitForNextTick()

        expect(resultCallbackSpy).toHaveBeenCalledTimes(2)
        expect(resultCallbackSpy).toHaveBeenLastCalledWith(
          expect.objectContaining({ data: refetchedSampleResult }),
        )
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

      it('refetch with error resolves with the error instead of rejecting', async () => {
        await scope.run(async () => {
          const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

          await waitFirstResult(queryHandlerObject)

          // Refetch after first load again.
          const { data, error } = await queryHandlerObject.refetch()

          expect(data).toBeNull()
          expect(error).toBe(queryHandlerObject.operationError().value)
          expect(error).toBeTruthy()
        })
      })

      it('reports a failed lazy load without an unhandled rejection', async () => {
        await scope.run(async () => {
          const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

          queryHandlerObject.load()

          await vi.waitFor(() => expect(queryHandlerObject.operationError().value).toBeTruthy())
        })
      })
    })

    describe('fetchMore and refetch after a successful first page', () => {
      beforeEach(() => {
        mockClient()
      })

      it.each([
        ['fetchMore', 'GraphQL', GraphQLErrorTypes.UnknownError],
        ['fetchMore', 'NetworkError', GraphQLErrorTypes.NetworkError],
        ['refetch', 'GraphQL', GraphQLErrorTypes.UnknownError],
        ['refetch', 'NetworkError', GraphQLErrorTypes.NetworkError],
      ] as const)(
        'reports a failed %s with a %s error once and resolves with it',
        async (method, errorType, expectedType) => {
          await scope.run(async () => {
            const errorCallback = vi.fn()
            const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), { errorCallback })

            await waitFirstResult(queryHandlerObject)

            handlerCallSpy.mockImplementation(() =>
              errorType === 'GraphQL'
                ? Promise.resolve(querySampleErrorResult)
                : Promise.reject(querySampleNetworkErrorResult),
            )

            const { data, error } =
              method === 'fetchMore'
                ? await queryHandlerObject.fetchMore({})
                : await queryHandlerObject.refetch()

            expect(data).toBeNull()
            expect(error).toBeTruthy()
            expect(errorCallback).toHaveBeenCalledOnce()
            expect(errorCallback).toHaveBeenCalledWith(
              expect.objectContaining({ type: expectedType }),
            )
          })
        },
      )
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

        await expect(queryHandlerObject.fetchMore({})).resolves.toEqual({ data: querySampleResult })
      })
    })
  })

  describe('fetchMore with a pagination field policy', () => {
    const ItemsDocument = gql`
      query items($pageSize: Int!, $cursor: String) {
        items(first: $pageSize, after: $cursor) {
          edges {
            cursor
            node {
              id
            }
          }
          pageInfo {
            endCursor
            hasNextPage
          }
        }
      }
    `

    const itemsPage = (cursor?: string) => {
      const start = Number(cursor ?? 0)

      return {
        items: {
          __typename: 'ItemConnection',
          edges: Array.from({ length: 10 }, (_, index) => ({
            __typename: 'ItemEdge',
            cursor: String(start + index + 1),
            node: { __typename: 'Item', id: String(start + index + 1) },
          })),
          pageInfo: {
            __typename: 'PageInfo',
            endCursor: String(start + 10),
            hasNextPage: start === 0,
          },
        },
      }
    }

    // Answers like the server, a macrotask later, so the merged page reaches the query the way it
    //   does in the browser.
    const requestedCursors: unknown[] = []

    beforeEach(() => {
      requestedCursors.length = 0

      provideApolloClient(
        new ApolloClient({
          link: new ApolloLink(
            (operation) =>
              new Observable((observer) => {
                requestedCursors.push(operation.variables.cursor)

                setTimeout(() => {
                  observer.next({ data: itemsPage(operation.variables.cursor) })
                  observer.complete()
                })
              }),
          ),
          cache: new InMemoryCache({
            typePolicies: { Query: { fields: { items: relayStylePagination() } } },
          }),
          devtools: { enabled: false },
        }),
      )
    })

    // An infinite scroll asks for the next page as soon as the previous one resolved, and still
    //   sitting at the bottom is all it goes by. Resolving ahead of the merged page made it ask for
    //   the same page over and over, each request dropping the page before.
    it('resolves once the merged page is in the result', async () => {
      await scope.run(async () => {
        const queryHandlerObject = new QueryHandler(
          useQuery<ReturnType<typeof itemsPage>, { pageSize: number; cursor?: string }>(
            ItemsDocument,
            { pageSize: 10 },
            { fetchPolicy: 'cache-first' },
          ),
        )

        await vi.waitFor(() =>
          expect(queryHandlerObject.result().value?.items.edges).toHaveLength(10),
        )

        await queryHandlerObject.fetchMore({ variables: { cursor: '10' } })

        expect(queryHandlerObject.result().value?.items.edges).toHaveLength(20)

        await queryHandlerObject.fetchMore({ variables: { cursor: '20' } })

        expect(queryHandlerObject.result().value?.items.edges).toHaveLength(30)
        expect(requestedCursors).toEqual([undefined, '10', '20'])
      })
    })
  })

  describe('subscribeToMore', () => {
    let mockSubscription: IMockSubscription

    // Records how often, and with which variables, a subscription was opened.
    let subscriptionHandlerSpy: Mock<(variables: unknown) => IMockSubscription>

    // Every example gets its own scope, so that the subscription of one does not
    //  receive the error of the next one.
    let subscriptionScope: ReturnType<typeof effectScope>

    // Apollo logs an unhandled subscription error itself; capture it instead of
    //  letting it fail the test.
    const withDevelopmentDiagnostics = (emitError: () => void) => {
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      emitError()

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

    // Each opened subscription gets its own mock, so that an emission can be
    //  routed to a specific one of them.
    const trackOpenedSubscriptions = () => {
      const openedSubscriptions: IMockSubscription[] = []

      subscriptionHandlerSpy.mockImplementation(() => {
        const subscription = createMockSubscription()
        openedSubscriptions.push(subscription)
        return subscription
      })

      return openedSubscriptions
    }

    const sampleUpdatedResult = {
      data: {
        sampleUpdated: {
          __typename: 'Sample',
          id: 1,
          title: 'Updated Title',
          text: 'Updated Text',
        },
      },
    }

    beforeEach(() => {
      mockSubscription = createMockSubscription()
      subscriptionHandlerSpy = vi.fn(() => mockSubscription)

      mockClient()

      createMockClient([
        {
          operationDocument: SampleTypedSubscriptionDocument,
          handler: subscriptionHandlerSpy,
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

    it('re-subscribes with the new options when the reactive options change', async () => {
      await subscriptionScope.run(async () => {
        const openedSubscriptions = trackOpenedSubscriptions()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        const subscriptionId = ref(1)
        const updateQuerySpy = vi.fn()

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(() =>
          subscribeToMoreOptions({
            variables: { id: subscriptionId.value },
            updateQuery: updateQuerySpy,
          }),
        )

        expect(subscriptionHandlerSpy).toHaveBeenCalledTimes(1)
        expect(subscriptionHandlerSpy).toHaveBeenLastCalledWith({ id: 1 })

        subscriptionId.value = 2
        await waitForNextTick()

        expect(subscriptionHandlerSpy).toHaveBeenCalledTimes(2)
        expect(subscriptionHandlerSpy).toHaveBeenLastCalledWith({ id: 2 })

        openedSubscriptions[0].next(sampleUpdatedResult)

        expect(updateQuerySpy).not.toHaveBeenCalled()

        openedSubscriptions[1].next(sampleUpdatedResult)

        expect(updateQuerySpy).toHaveBeenCalledTimes(1)
      })
    })

    it('subscribes a lazy query only once it was loaded', async () => {
      await subscriptionScope.run(async () => {
        const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(
          subscribeToMoreOptions(),
        )

        expect(subscriptionHandlerSpy).not.toHaveBeenCalled()

        queryHandlerObject.load()
        await waitForNextTick()

        expect(subscriptionHandlerSpy).toHaveBeenCalledTimes(1)
      })
    })

    it('re-subscribes when the query is restarted', async () => {
      await subscriptionScope.run(async () => {
        const openedSubscriptions = trackOpenedSubscriptions()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        const updateQuerySpy = vi.fn()

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(
          subscribeToMoreOptions({ updateQuery: updateQuerySpy }),
        )

        expect(subscriptionHandlerSpy).toHaveBeenCalledTimes(1)

        queryHandlerObject.stop()
        queryHandlerObject.start()
        await waitForNextTick()

        expect(subscriptionHandlerSpy).toHaveBeenCalledTimes(2)

        openedSubscriptions[0].next(sampleUpdatedResult)

        expect(updateQuerySpy).not.toHaveBeenCalled()

        openedSubscriptions[1].next(sampleUpdatedResult)

        expect(updateQuerySpy).toHaveBeenCalledTimes(1)
      })
    })

    it('hands null to updateQuery while the cache holds no result yet', async () => {
      await subscriptionScope.run(async () => {
        handlerCallSpy.mockImplementationOnce(
          () =>
            new Promise((resolve) => {
              setTimeout(() => resolve({ data: querySampleResult }), 10)
            }),
        )

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 4711 }))
        const updateQuerySpy = vi.fn()

        queryHandlerObject.subscribeToMore<SampleUpdatedSubscriptionVariables>(
          subscribeToMoreOptions({ updateQuery: updateQuerySpy }),
        )

        mockSubscription.next(sampleUpdatedResult)

        // Apollo Client 3 passed an empty object here.
        expect(updateQuerySpy).toHaveBeenCalledWith(
          null,
          expect.objectContaining({ complete: false, previousData: null }),
        )

        await vi.waitFor(() => expect(queryHandlerObject.result().value).toBeTruthy())
      })
    })
  })
})
