// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useMutation } from '@vue/apollo-composable'

import { SampleTypedMutationDocument } from '#tests/fixtures/graphqlSampleTypes.ts'
import type {
  SampleUpdateMutation,
  SampleUpdateMutationVariables,
} from '#tests/fixtures/graphqlSampleTypes.ts'
import createMockClient from '#tests/support/mock-apollo-client.ts'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import UserError from '#shared/errors/UserError.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import MutationHandler from '../MutationHandler.ts'

const mutationFunctionCallSpy = vi.fn()

let mutationSampleResult: Record<string, unknown> = {
  Sample: {
    __typename: 'Sample',
    id: 1,
    title: 'Test Title',
    text: 'Test Text',
    errors: null,
  },
}

let errorType = 'Exceptions::UnknownError'

const getMutationSampleErrorResult = () => {
  return {
    errors: [
      {
        message: 'GraphQL Error',
        extensions: { type: errorType },
      },
    ],
  }
}

const mutationSampleNetworkErrorResult = new Error('GraphQL Network Error')

const mockClient = (error = false, errorType = 'GraphQL') => {
  createMockClient([
    {
      operationDocument: SampleTypedMutationDocument,
      handler: () => {
        if (error) {
          return errorType === 'GraphQL'
            ? Promise.resolve(getMutationSampleErrorResult())
            : Promise.reject(mutationSampleNetworkErrorResult)
        }

        return Promise.resolve({
          data: mutationSampleResult,
        })
      },
    },
  ])

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
      const errorNotificationMessage = 'A test message.'

      const mutationHandlerObject = new MutationHandler(sampleMutation(), {
        errorNotificationMessage,
      })
      expect(
        mutationHandlerObject.handlerOptions.errorNotificationMessage,
      ).toBe(errorNotificationMessage)
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

  describe('send', () => {
    beforeEach(() => {
      mockClient()
    })

    it('result is available', async () => {
      const mutationHandlerObject = new MutationHandler(sampleMutation())

      await expect(
        mutationHandlerObject.send({ id: 1, Sample: {} }),
      ).resolves.toEqual(mutationSampleResult)
    })

    it('result with user error', async () => {
      const userErrors = [
        {
          field: null,
          message: 'Example error message',
        },
        {
          field: 'id',
          message: 'Id field is wrong',
        },
      ]
      const userErrorObject = new UserError(userErrors)

      mutationSampleResult = {
        Sample: {
          id: null,
          title: null,
          text: null,
          errors: userErrors,
        },
      }

      const mutationHandlerObject = new MutationHandler(sampleMutation())

      await expect(mutationHandlerObject.send()).rejects.toEqual(
        userErrorObject,
      )
    })
  })

  describe('error handling', () => {
    describe('GraphQL errors', () => {
      it('notification is triggerd', async () => {
        mockClient(true)

        expect.assertions(1)
        const mutationHandlerObject = new MutationHandler(sampleMutation())

        await mutationHandlerObject.send().catch(() => {
          return null
        })

        const { notifications } = useNotifications()

        expect(notifications.value.length).toBe(1)
      })

      it('use error callback', async () => {
        mockClient(true)

        expect.assertions(1)

        const errorCallbackSpy = vi.fn()

        const mutationHandlerObject = new MutationHandler(sampleMutation(), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        await mutationHandlerObject.send().catch(() => {
          return null
        })

        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: 'Exceptions::UnknownError',
          message: 'GraphQL Error',
        })
      })

      it('use error callback with known error type', async () => {
        errorType = 'Exceptions::Forbidden'
        mockClient(true)

        expect.assertions(1)

        const errorCallbackSpy = vi.fn()

        const mutationHandlerObject = new MutationHandler(sampleMutation(), {
          errorCallback: (error) => {
            errorCallbackSpy(error)
          },
        })

        await mutationHandlerObject.send().catch(() => {
          return null
        })

        expect(errorCallbackSpy).toHaveBeenCalledWith({
          type: 'Exceptions::Forbidden',
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

        await mutationHandlerObject.send().catch(() => {
          return null
        })
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
      mutationHandlerObject.send().catch(() => {
        return null
      })
      expect(mutationHandlerObject.called().value).toBe(true)
    })
  })
})
