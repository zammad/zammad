// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useSubscription } from '@vue/apollo-composable'
import { createMockSubscription, IMockSubscription } from 'mock-apollo-client'
import createMockClient from '@tests/support/mock-apollo-client'
import SubscriptionHandler from '@common/server/apollo/handler/SubscriptionHandler'
import {
  SampleTypedSubscriptionDocument,
  SampleUpdatedSubscription,
  SampleUpdatedSubscriptionVariables,
} from '@tests/fixtures/graphqlSampleTypes'
import useNotifications from '@common/composables/useNotifications'
import { NetworkStatus } from '@apollo/client/core'

const subscriptionFunctionCallSpy = jest.fn()

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
      extensions: { type: 'Exceptions::NotAuthorized' },
    },
  ],
}

// const querySampleNetworkErrorResult = new Error('GraphQL Network Error')

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
      const subscriptionHandlerObject = new SubscriptionHandler(
        sampleSubscription({ id: 1 }),
      )
      expect(subscriptionHandlerObject).toBeInstanceOf(SubscriptionHandler)
    })

    it('default handler options can be changed', () => {
      const errorNotitifactionMessage = 'A test message.'

      const subscriptionHandlerObject = new SubscriptionHandler(
        sampleSubscription({ id: 1 }),
        {
          errorNotitifactionMessage,
        },
      )
      expect(
        subscriptionHandlerObject.handlerOptions.errorNotitifactionMessage,
      ).toBe(errorNotitifactionMessage)
    })

    it('given subscription function was executed', () => {
      const subscriptionHandlerObject = new SubscriptionHandler(
        sampleSubscription({ id: 1 }),
      )
      expect(subscriptionFunctionCallSpy).toBeCalled()
      expect(subscriptionHandlerObject.operationResult).toBeTruthy()
    })
  })

  describe('loading', () => {
    beforeEach(() => {
      mockClient()
    })

    it('loading state will be updated', async () => {
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

  describe('result/subscribe', () => {
    beforeEach(() => {
      mockClient()
    })

    it('subscribed', async () => {
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

    it('watch on result change', async () => {
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

    it('register onResult callback', async () => {
      expect.assertions(1)
      const subscriptionHandlerObject = new SubscriptionHandler(
        sampleSubscription({ id: 1 }),
      )

      const resultCallbackSpy = jest.fn()

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

  describe('error handling', () => {
    describe('GraphQL errors', () => {
      beforeEach(() => {
        mockClient()
      })

      it('notification is triggerd', () => {
        expect.assertions(2)
        const subscriptionHandlerObject = new SubscriptionHandler(
          sampleSubscription({ id: 1 }),
        )

        mockSubscription.next(subscriptionSampleErrorResult)

        expect(subscriptionHandlerObject.operationError().value).toBeTruthy()

        const { notifications } = useNotifications()
        expect(notifications.value.length).toBe(1)
      })

      it('use error callback', () => {
        expect.assertions(2)

        const errorCallbackSpy = jest.fn()

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
          type: 'Exceptions::NotAuthorized',
          message: 'GraphQL Error',
        })
      })
    })
  })

  describe('use operation result wrapper', () => {
    beforeEach(() => {
      mockClient()
    })

    it('use returned query options', () => {
      const subscriptionHandlerObject = new SubscriptionHandler(
        sampleSubscription({ id: 1 }),
      )

      expect(subscriptionHandlerObject.options()).toBeTruthy()
    })
  })
})
