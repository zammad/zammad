// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useLazyQuery, useQuery } from '@vue/apollo-composable'
import createMockClient from '@tests/support/mock-apollo-client'
import type {
  SampleQuery,
  SampleQueryVariables,
} from '@tests/fixtures/graphqlSampleTypes'
import { SampleTypedQueryDocument } from '@tests/fixtures/graphqlSampleTypes'
import { useNotifications } from '@shared/components/CommonNotifications'
import { NetworkStatus } from '@apollo/client/core'
import { GraphQLErrorTypes } from '@shared/types/error'
import QueryHandler from '../QueryHandler'

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
      extensions: { type: 'Exceptions::Unknown' },
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

describe('QueryHandler', () => {
  const sampleQuery = (variables: SampleQueryVariables, options = {}) => {
    queryFunctionCallSpy()
    return useQuery<SampleQuery, SampleQueryVariables>(
      SampleTypedQueryDocument,
      variables,
      options,
    )
  }

  describe('constructor', () => {
    beforeEach(() => {
      mockClient()
    })

    it('instance can be created', () => {
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
      expect(queryHandlerObject).toBeInstanceOf(QueryHandler)
    })
    it('default handler options can be changed', () => {
      const errorNotificationMessage = 'A test message.'

      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
        errorNotificationMessage,
      })
      expect(queryHandlerObject.handlerOptions.errorNotificationMessage).toBe(
        errorNotificationMessage,
      )
    })

    it('given query function was executed', () => {
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
      expect(queryFunctionCallSpy).toBeCalled()
      expect(queryHandlerObject.operationResult).toBeTruthy()
    })
  })

  describe('loading', () => {
    beforeEach(() => {
      mockClient()
    })

    it('loading state will be updated', async () => {
      expect.assertions(2)

      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))
      expect(queryHandlerObject.loading().value).toBe(true)

      await queryHandlerObject.onLoaded()

      expect(queryHandlerObject.loading().value).toBe(false)
    })

    it('supports lazy queries', async () => {
      expect.assertions(3)

      const sampleLazyQuery = (
        variables: SampleQueryVariables,
        options = {},
      ) => {
        queryFunctionCallSpy()
        return useLazyQuery<SampleQuery, SampleQueryVariables>(
          SampleTypedQueryDocument,
          variables,
          options,
        )
      }

      const queryHandlerObject = new QueryHandler(sampleLazyQuery({ id: 1 }))

      expect(queryHandlerObject.loading().value).toBe(false)

      await queryHandlerObject.load()

      expect(queryHandlerObject.loading().value).toBe(true)

      await queryHandlerObject.onLoaded()

      expect(queryHandlerObject.loading().value).toBe(false)
    })
  })

  describe('result', () => {
    beforeEach(() => {
      mockClient()
    })

    it('result is available', async () => {
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      await expect(queryHandlerObject.loadedResult()).resolves.toEqual(
        querySampleResult,
      )
    })

    it('loaded result is also resolved after additional result call with active trigger refetch', async () => {
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      await expect(queryHandlerObject.loadedResult()).resolves.toEqual(
        querySampleResult,
      )

      await expect(queryHandlerObject.loadedResult(true)).resolves.toEqual(
        querySampleResult,
      )
    })

    it('watch on result change', async () => {
      expect.assertions(1)

      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      queryHandlerObject.watchOnResult((result) => {
        expect(result).toEqual(querySampleResult)
      })
      await queryHandlerObject.onLoaded()
    })

    it('on result trigger', async () => {
      expect.assertions(1)

      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      queryHandlerObject.onResult((result) => {
        expect(result.data).toEqual(querySampleResult)
      })
      await queryHandlerObject.onLoaded()
    })

    it('receive value immediately in non-reactive way', async () => {
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      await expect(queryHandlerObject.trigger()).resolves.toEqual(
        querySampleResult,
      )

      expect(handlerCallSpy).toHaveBeenCalledOnce()

      await expect(queryHandlerObject.trigger()).resolves.toEqual(
        querySampleResult,
      )

      expect(handlerCallSpy).toHaveBeenCalledOnce()
    })
  })

  describe('error handling', () => {
    describe('GraphQL errors', () => {
      beforeEach(() => {
        mockClient(true)
      })

      it('notification is triggerd', async () => {
        expect.assertions(1)

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        await queryHandlerObject.loadedResult()

        const { notifications } = useNotifications()

        expect(notifications.value.length).toBe(1)
      })

      it('use error callback', async () => {
        expect.assertions(1)

        const errorCallbackSpy = vi.fn()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        await queryHandlerObject.loadedResult()

        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: 'Exceptions::Unknown',
          message: 'GraphQL Error',
        })
      })

      it('refetch with error', async () => {
        expect.assertions(1)
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        const errorCallbackSpy = vi.fn()

        await queryHandlerObject.loadedResult()

        // Refetch after first load again.
        await queryHandlerObject.refetch().catch((error) => {
          errorCallbackSpy(error)
        })

        expect(errorCallbackSpy).toHaveBeenCalled()
      })
    })

    describe('Network errors', () => {
      beforeEach(() => {
        mockClient(true, 'NetworkError')
      })

      it('use error callback', async () => {
        expect.assertions(1)
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
          errorCallback: (error) => {
            expect(error).toEqual({
              type: GraphQLErrorTypes.NetworkError,
            })
          },
        })

        await queryHandlerObject.loadedResult()
      })
    })
  })

  describe('use operation result wrapper', () => {
    beforeEach(() => {
      mockClient()
    })

    it('use returned query options', () => {
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      expect(queryHandlerObject.options()).toBeTruthy()
    })

    it('use fetchMore query function', async () => {
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      await expect(queryHandlerObject.fetchMore({})).resolves.toEqual(
        querySampleResult,
      )
    })
  })
})
