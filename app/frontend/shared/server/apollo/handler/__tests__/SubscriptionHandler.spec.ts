// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { NetworkStatus } from '@apollo/client/core'
import { useSubscription } from '@vue/apollo-composable'
import { createMockSubscription } from 'mock-apollo-client'
import { effectScope } from 'vue'

import { SampleTypedSubscriptionDocument } from '#tests/fixtures/graphqlSampleTypes.ts'
import type {
  SampleUpdatedSubscription,
  SampleUpdatedSubscriptionVariables,
} from '#tests/fixtures/graphqlSampleTypes.ts'
import createMockClient from '#tests/support/mock-apollo-client.ts'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'

import SubscriptionHandler from '../SubscriptionHandler.ts'

import type { IMockSubscription } from 'mock-apollo-client'

const subscriptionFunctionCallSpy = vi.fn()

const subscriptionSampleResult = {
  sampleUpdated: { id: 1, title: 'Test Title', text: 'Test Text' },
}

const subscriptionSampleResultUpdated = {
  sampleUpdated: { id: 1, title: 'Test Title2', text: 'Test Text2' },
}

const subscriptionSampleErrorResult = {
  networkStatus: NetworkStatus.error,
  errors: [
    {
      message: 'GraphQL Error',
      extensions: { type: 'Exceptions::UnknownError' },
    },
  ],
}

let mockSubscription: IMockSubscription

const mockClient = () => {
  mockSubscription = createMockSubscription()

  createMockClient([
    {
      operationDocument: SampleTypedSubscriptionDocument,
      handler: () => mockSubscription,
    },
  ])

  subscriptionFunctionCallSpy.mockClear()
}

const scope = effectScope()

describe('SubscriptionHandler', () => {
  const sampleSubscription = (
    variables: SampleUpdatedSubscriptionVariables,
    options = {},
  ) => {
    subscriptionFunctionCallSpy()
    return useSubscription<
      SampleUpdatedSubscription,
      SampleUpdatedSubscriptionVariables
    >(SampleTypedSubscriptionDocument, variables, options)
  }

  describe('constructor', () => {
    beforeEach(() => {
      mockClient()
    })

    it('instance can be created', () => {
      scope.run(() => {
        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )
        expect(subscriptionHandlerObject).toBeInstanceOf(SubscriptionHandler)
      })
    })

    it('default handler options can be changed', () => {
      scope.run(() => {
        const errorNotificationMessage = 'A test message.'

        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
          {
            errorNotificationMessage,
          },
        )
        expect(
          subscriptionHandlerObject.handlerOptions.errorNotificationMessage,
        ).toBe(errorNotificationMessage)
      })
    })

    it('given subscription function was executed', () => {
      scope.run(() => {
        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )
        expect(subscriptionFunctionCallSpy).toBeCalled()
        expect(subscriptionHandlerObject.operationResult).toBeTruthy()
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

        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )
        expect(subscriptionHandlerObject.loading().value).toBe(true)

        const subscribed = subscriptionHandlerObject.onSubscribed()

        mockSubscription.next({
          data: subscriptionSampleResult,
        })

        await subscribed

        expect(subscriptionHandlerObject.loading().value).toBe(false)
      })
    })
  })

  describe('result/subscribe', () => {
    beforeEach(() => {
      mockClient()
    })

    it('subscribed', async () => {
      await scope.run(async () => {
        expect.assertions(1)
        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )

        const subscribed = subscriptionHandlerObject.onSubscribed()

        mockSubscription.next({
          data: subscriptionSampleResult,
        })

        const result = await subscribed

        expect(result).toEqual(subscriptionSampleResult)
      })
    })

    it('watch on result change', async () => {
      await scope.run(async () => {
        expect.assertions(2)
        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )

        const subscribed = subscriptionHandlerObject.onSubscribed()

        mockSubscription.next({
          data: subscriptionSampleResult,
        })

        await subscribed

        let watchCount = 0
        subscriptionHandlerObject.watchOnResult((result) => {
          expect(result).toEqual(
            watchCount === 0
              ? subscriptionSampleResult
              : subscriptionSampleResultUpdated,
          )
          watchCount += 1
        })

        mockSubscription.next({
          data: subscriptionSampleResultUpdated,
        })
      })
    })

    it('register onResult callback', async () => {
      await scope.run(async () => {
        expect.assertions(1)

        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )

        const resultCallbackSpy = vi.fn()

        const subscribed = subscriptionHandlerObject.onSubscribed()

        mockSubscription.next({
          data: subscriptionSampleResult,
        })

        await subscribed

        subscriptionHandlerObject.onResult((result) => {
          resultCallbackSpy(result)
        })

        mockSubscription.next({
          data: subscriptionSampleResultUpdated,
        })

        expect(resultCallbackSpy).toHaveBeenCalledWith({
          data: subscriptionSampleResultUpdated,
        })
      })
    })
  })

  describe('error handling', () => {
    describe('GraphQL errors', () => {
      beforeEach(() => {
        mockClient()
      })

      it('notification is triggerd', () => {
        scope.run(() => {
          const subscriptionHandlerObject = new SubscriptionHandler(
            sampleSubscription({ id: 1 }),
          )

          mockSubscription.next(subscriptionSampleErrorResult)

          expect(subscriptionHandlerObject.operationError().value).toBeTruthy()

          const { notifications } = useNotifications()
          expect(notifications.value.length).toBe(1)
        })
      })

      it('use error callback', () => {
        scope.run(() => {
          const errorCallbackSpy = vi.fn()

          const subscriptionHandlerObject = new SubscriptionHandler(
            sampleSubscription({ id: 1 }),
            {
              errorCallback: (error) => {
                errorCallbackSpy(error)
              },
            },
          )

          mockSubscription.next(subscriptionSampleErrorResult)

          expect(subscriptionHandlerObject.operationError().value).toBeTruthy()

          expect(errorCallbackSpy).toHaveBeenCalledWith({
            type: 'Exceptions::UnknownError',
            message: 'GraphQL Error',
          })
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
        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )

        expect(subscriptionHandlerObject.options()).toBeTruthy()
      })
    })
  })
})
