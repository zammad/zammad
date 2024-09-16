// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { NetworkStatus } from '@apollo/client/core'
import { useLazyQuery, useQuery } from '@vue/apollo-composable'
import { effectScope } from 'vue'

import { SampleTypedQueryDocument } from '#tests/fixtures/graphqlSampleTypes.ts'
import type {
  SampleQuery,
  SampleQueryVariables,
} from '#tests/fixtures/graphqlSampleTypes.ts'
import createMockClient from '#tests/support/mock-apollo-client.ts'
import { waitForNextTick, waitUntilSpyCalled } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import QueryHandler from '../QueryHandler.ts'

import type { ApolloError, ApolloQueryResult } from '@apollo/client/core'

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

    it('on result trigger', async () => {
      await scope.run(async () => {
        expect.assertions(1)

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        queryHandlerObject.onResult((result) => {
          if (result.data) {
            expect(result.data).toEqual(querySampleResult)
          }
        })
        await waitFirstResult(queryHandlerObject)
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
        await expect(result1).resolves.toEqual(
          expect.objectContaining({ data: querySampleResult }),
        )
        await expect(result2).resolves.toEqual(
          expect.objectContaining({ data: querySampleResult }),
        )
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

        await expect(queryHandlerObject.fetchMore({})).resolves.toEqual(
          querySampleResult,
        )
      })
    })
  })
})
