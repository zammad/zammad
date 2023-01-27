// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { CurrentUserDocument } from '@shared/graphql/queries/currentUser.api'
import { CurrentUserUpdatesDocument } from '@shared/graphql/subscriptions/currentUserUpdates.api'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import { createPinia, setActivePinia } from 'pinia'
import { useSessionStore } from '../session'

const userData = {
  __typename: 'User',
  id: '123456789',
  internalId: 1,
  firstname: 'John',
  lastname: 'Doe',
  fullname: 'John Doe',
  email: 'zammad@example.com',
  image: 'c2715a3e92c7e375b8c212d25d431e2a',
  preferences: {
    locale: 'de-de',
  },
  objectAttributeValues: [],
  organization: {
    __typename: 'Organization',
    id: '234241',
    internalId: 1,
    name: 'Zammad Foundation',
    objectAttributeValues: [],
    active: true,
  },
  permissions: {
    __typename: 'Permission',
    names: ['admin'],
  },
  hasSecondaryOrganizations: false,
}

describe('Session Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('is empty by default', () => {
    const session = useSessionStore()

    expect(session.id).toBe(null)
    expect(session.user).toBe(null)
  })

  it('get current user and check on user update subscription', async () => {
    const session = useSessionStore()

    mockGraphQLApi(CurrentUserDocument).willResolve({
      currentUser: userData,
    })
    const userUpdateSubscription = mockGraphQLSubscription(
      CurrentUserUpdatesDocument,
    )

    await session.getCurrentUser()

    expect(session.user).toEqual(userData)

    const updatedUserData = {
      ...userData,
      firstname: 'Jane',
      lastname: 'Doe',
      fullname: 'Jane Doe',
    }

    await userUpdateSubscription.next({
      data: {
        userUpdates: {
          __typename: 'UserUpdatesPayload',
          user: updatedUserData,
        },
      },
    })

    expect(session.user).toEqual(updatedUserData)
  })
})
