// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useQuery, provideApolloClient } from '@vue/apollo-composable'
import { createMockClient } from 'mock-apollo-client'
import QueryHandler from '@common/server/apollo/handler/QueryHandler'
import {
  SampleTypedQueryDocument,
  SampleQuery,
  SampleQueryVariables,
} from '@tests/fixtures/graphqlSampleTypes'
import useNotifications from '@common/composables/useNotifications'
import { NetworkStatus } from '@apollo/client/core'
import { GraphQLErrorTypes } from '@common/types/error'

const queryFunctionCallSpy = jest.fn()

const querySampleResult = {
  Sample: { id: 1, title: 'Test Title', text: 'Test Text' },
}

const querySampleErrorResult = {
  networkStatus: NetworkStatus.error,
  errors: [
    {
      message: 'GraphQL Error',
      extensions: { type: 'Exceptions::NotAuthorized' },
    },
  ],
}

const querySampleNetworkErrorResult = new Error('GraphQL Network Error')

const mockClient = (error = false, errorType = 'GraphQL') => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(SampleTypedQueryDocument, () => {
    if (error) {
      return errorType === 'GraphQL'
        ? Promise.resolve(querySampleErrorResult)
        : Promise.reject(querySampleNetworkErrorResult)
    }

    return Promise.resolve({
      data: querySampleResult,
    })
  })

  provideApolloClient(mockApolloClient)

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
      const errorNotitifactionMessage = 'A test message.'

      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
        errorNotitifactionMessage,
      })
      expect(queryHandlerObject.handlerOptions.errorNotitifactionMessage).toBe(
        errorNotitifactionMessage,
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
  })

  describe('result', () => {
    beforeEach(() => {
      mockClient()
    })

    it('result is available', async () => {
      expect.assertions(1)
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      const result = await queryHandlerObject.loadedResult()
      expect(result).toEqual(querySampleResult)
    })

    it('loaded result is also resolved after additional result call with active trigger refetch', async () => {
      expect.assertions(2)
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      let result = await queryHandlerObject.loadedResult()
      expect(result).toEqual(querySampleResult)

      result = await queryHandlerObject.loadedResult(true)
      expect(result).toEqual(querySampleResult)
    })

    it('watch on result change', async () => {
      expect.assertions(1)
      const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

      queryHandlerObject.watchOnResult((result) => {
        expect(result).toEqual(querySampleResult)
      })
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

        const errorCallbackSpy = jest.fn()

        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        await queryHandlerObject.loadedResult()

        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: 'Exceptions::NotAuthorized',
          message: 'GraphQL Error',
        })
      })

      it('refetch with error', async () => {
        expect.assertions(1)
        const queryHandlerObject = new QueryHandler(sampleQuery({ id: 1 }))

        const errorCallbackSpy = jest.fn()

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
  })
})
