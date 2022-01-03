// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useMutation, provideApolloClient } from '@vue/apollo-composable'
import { createMockClient } from 'mock-apollo-client'
import MutationHandler from '@common/server/apollo/handler/MutationHandler'
import {
  SampleUpdateMutation,
  SampleUpdateMutationVariables,
  SampleTypedMutationDocument,
} from '@tests/fixtures/graphqlSampleTypes'
import useNotifications from '@common/composables/useNotifications'
import { GraphQLErrorTypes } from '@common/types/error'

const mutationFunctionCallSpy = jest.fn()

const mutationSampleResult = {
  Sample: { id: 1, title: 'Test Title', text: 'Test Text' },
}

const mutationSampleErrorResult = {
  errors: [
    {
      message: 'GraphQL Error',
      extensions: { type: 'Exceptions::NotAuthorized' },
    },
  ],
}

const mutationSampleNetworkErrorResult = new Error('GraphQL Network Error')

const mockClient = (error = false, errorType = 'GraphQL') => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(SampleTypedMutationDocument, () => {
    if (error) {
      return errorType === 'GraphQL'
        ? Promise.resolve(mutationSampleErrorResult)
        : Promise.reject(mutationSampleNetworkErrorResult)
    }

    return Promise.resolve({
      data: mutationSampleResult,
    })
  })

  provideApolloClient(mockApolloClient)

  mutationFunctionCallSpy.mockClear()
}

describe('MutationHandler', () => {
  const sampleMutation = () => {
    mutationFunctionCallSpy()
    return useMutation<SampleUpdateMutation, SampleUpdateMutationVariables>(
      SampleTypedMutationDocument,
    )
  }

  describe('constructor', () => {
    beforeEach(() => {
      mockClient()
    })

    it('instance can be created', () => {
      const mutationHandlerObject = new MutationHandler(sampleMutation())
      expect(mutationHandlerObject).toBeInstanceOf(MutationHandler)
    })

    it('default handler options can be changed', () => {
      const errorNotitifactionMessage = 'A test message.'

      const mutationHandlerObject = new MutationHandler(sampleMutation(), {
        errorNotitifactionMessage,
      })
      expect(
        mutationHandlerObject.handlerOptions.errorNotitifactionMessage,
      ).toBe(errorNotitifactionMessage)
    })

    it('given mutation function was executed', () => {
      const mutationHandlerObject = new MutationHandler(sampleMutation())
      expect(mutationFunctionCallSpy).toBeCalled()
      expect(mutationHandlerObject.operationResult).toBeTruthy()
    })
  })

  describe('loading', () => {
    beforeEach(() => {
      mockClient()
    })

    it('loading state should be false without called send function', () => {
      const mutationHandlerObject = new MutationHandler(sampleMutation())
      expect(mutationHandlerObject.loading().value).toBe(false)
    })

    it('loading state should be changed after called send function', () => {
      expect.assertions(1)
      const mutationHandlerObject = new MutationHandler(sampleMutation())
      mutationHandlerObject.send()
      expect(mutationHandlerObject.loading().value).toBe(true)
    })

    it('loading state will be updated', async () => {
      expect.assertions(1)
      const mutationHandlerObject = new MutationHandler(sampleMutation())
      await mutationHandlerObject.send()

      expect(mutationHandlerObject.loading().value).toBe(false)
    })
  })

  describe('result', () => {
    beforeEach(() => {
      mockClient()
    })

    it('result is available', async () => {
      expect.assertions(1)
      const mutationHandlerObject = new MutationHandler(sampleMutation())
      const result = await mutationHandlerObject.send({ id: 1, Sample: {} })

      expect(result).toEqual(result)
    })
  })

  describe('error handling', () => {
    describe('GraphQL errors', () => {
      beforeEach(() => {
        mockClient(true)
      })

      it('notification is triggerd', async () => {
        expect.assertions(1)
        const mutationHandlerObject = new MutationHandler(sampleMutation())

        await mutationHandlerObject.send()

        const { notifications } = useNotifications()

        expect(notifications.value.length).toBe(1)
      })

      it('use error callback', async () => {
        expect.assertions(1)

        const errorCallbackSpy = jest.fn()

        const mutationHandlerObject = new MutationHandler(sampleMutation(), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        await mutationHandlerObject.send().catch(() => {
          return null
        })

        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: 'Exceptions::NotAuthorized',
          message: 'GraphQL Error',
        })
      })
    })

    describe('Network errors', () => {
      beforeEach(() => {
        mockClient(true, 'NetworkError')
      })

      it('use error callback', async () => {
        expect.assertions(1)
        const mutationHandlerObject = new MutationHandler(sampleMutation(), {
          errorCallback: (error) => {
            expect(error).toEqual({
              type: GraphQLErrorTypes.NetworkError,
            })
          },
        })

        await mutationHandlerObject.send()
      })
    })
  })

  describe('use operation result wrapper', () => {
    beforeEach(() => {
      mockClient()
    })

    it('check called', () => {
      const mutationHandlerObject = new MutationHandler(sampleMutation())

      expect(mutationHandlerObject.called().value).toBe(false)
      mutationHandlerObject.send()
      expect(mutationHandlerObject.called().value).toBe(true)
    })
  })
})
