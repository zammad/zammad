// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { getGraphQLSubscriptionHandler } from '../mocks.ts'

import { TestUserDocument, TestUserUpdatesDocument } from './queries.ts'
import { getQueryHandler, getSubscriptionHandler } from './utils.ts'

import type {
  TestUserQuery,
  TestUserUpdatesSubscription,
  TestUserUpdatesSubscriptionVariables,
} from './queries.ts'

describe('mocked subscription works correctly', () => {
  it('subscription returns data correctly when not mocked', async () => {
    const userId = convertToGraphQLId('User', 22)
    const handler = getSubscriptionHandler<TestUserUpdatesSubscription>(
      TestUserUpdatesDocument,
      { userId },
    )
    const results: (TestUserUpdatesSubscription | null | undefined)[] = []
    handler.onResult(({ data }) => {
      results.push(data)
    })
    const subscription = handler.getTestSubscriptionHandler()
    const mockedData = await subscription.trigger()

    expect(results).toHaveLength(1)

    const user = results[0]!.userUpdates!.user!

    expect(user.id).toBe(userId)
    expect(user.fullname).toBeTypeOf('string')

    expect(mockedData.userUpdates.user).toMatchObject(user)
    expect(user).not.toMatchObject(mockedData.userUpdates.user)

    expect(mockedData.userUpdates.user, 'mocked data is filled').toHaveProperty(
      'email',
    )
    expect(user, 'no email asked').not.toHaveProperty('email')
  })

  it('subscription returns mocked data correctly', async () => {
    const userId = convertToGraphQLId('User', 22)
    const fullname = 'John Doe'
    const handler = getSubscriptionHandler<TestUserUpdatesSubscription>(
      TestUserUpdatesDocument,
      { userId },
    )
    const results: (TestUserUpdatesSubscription | null | undefined)[] = []
    handler.onResult(({ data }) => {
      results.push(data)
    })
    const subscription = handler.getTestSubscriptionHandler()
    await subscription.trigger({
      userUpdates: {
        user: {
          id: userId,
          fullname,
        },
      },
    })

    expect(results).toHaveLength(1)

    const user = results[0]!.userUpdates!.user!

    expect(user.id).toBe(userId)
    expect(user.fullname).toBe(fullname)
    expect(user, 'no email asked').not.toHaveProperty('email')
  })

  it('data is updated when query was called and then subscription is triggered', async () => {
    const userId = convertToGraphQLId('User', 1)
    const queryHandler = getQueryHandler<TestUserQuery>(TestUserDocument, {
      userId,
    })
    queryHandler.subscribeToMore<TestUserUpdatesSubscriptionVariables>({
      document: TestUserUpdatesDocument,
      variables: { userId },
    })

    queryHandler.load()
    const reactiveResult = queryHandler.result()
    await flushPromises()

    const { data: mocked } = queryHandler.getMockedData()

    expect(reactiveResult.value?.user.id).toBe(userId)
    expect(reactiveResult.value?.user.fullname).toBe(mocked.user.fullname)

    const mockedSubscription =
      getGraphQLSubscriptionHandler<TestUserUpdatesSubscription>('userUpdates')

    await mockedSubscription.trigger({
      userUpdates: {
        user: {
          id: userId,
          fullname: 'Some New Name',
        },
      },
    })

    expect(reactiveResult.value?.user.fullname).toBe('Some New Name')
  })
})
