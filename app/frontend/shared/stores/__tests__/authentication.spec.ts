// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, execute, gql, Observable } from '@apollo/client/core'
import { createPinia, setActivePinia } from 'pinia'

import { mockGraphQLApi, mockGraphQLSubscription } from '#tests/support/mock-graphql-api.ts'

import { useNotifications } from '#shared/components/CommonNotifications/index.ts'
import { LogoutDocument } from '#shared/graphql/mutations/logout.api.ts'
import { ApplicationConfigDocument } from '#shared/graphql/queries/applicationConfig.api.ts'
import { ConfigUpdatesDocument } from '#shared/graphql/subscriptions/configUpdates.api.ts'
import trackSubscriptionsLink, {
  cancelActiveSubscriptions,
} from '#shared/server/apollo/link/trackSubscriptions.ts'
import {
  authenticationInvalidated,
  setAuthenticationInvalidated,
} from '#shared/server/apollo/utils/authenticationState.ts'

import { useAuthenticationStore } from '../authentication.ts'
import { useSessionStore } from '../session.ts'

vi.mock('#shared/server/apollo/client.ts', () => {
  return {
    clearApolloClientStore: () => Promise.resolve(),
  }
})

const subscriptionDocument = gql`
  subscription sampleUpdates {
    sampleUpdates {
      id
    }
  }
`

const mockUnauthenticatedConfig = () => {
  mockGraphQLApi(ApplicationConfigDocument).willResolve({
    applicationConfig: [{ key: 'product_name', value: 'Zammad' }],
  })
  mockGraphQLSubscription(ConfigUpdatesDocument)
}

const authenticateStore = () => {
  const authentication = useAuthenticationStore()
  const session = useSessionStore()

  authentication.authenticated = true
  session.id = '123456789'

  return authentication
}

// Starts a subscription through the real tracking link, so that the logout has
//  something to cancel. Its teardown is what unsubscribes the Action Cable
//  channel in the application.
const startTrackedSubscription = () => {
  const teardownSpy = vi.fn()

  const terminatingLink = new ApolloLink(() => new Observable(() => teardownSpy))

  execute(ApolloLink.from([trackSubscriptionsLink, terminatingLink]), {
    query: subscriptionDocument,
  }).subscribe(() => {})

  return teardownSpy
}

describe('Authentication Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    mockUnauthenticatedConfig()
    useNotifications().clearAllNotifications()
  })

  afterEach(() => {
    // Make sure no state of a previous example is left behind.
    cancelActiveSubscriptions()
    setAuthenticationInvalidated(false)
  })

  it('clears the authentication after a logout', async () => {
    mockGraphQLApi(LogoutDocument).willResolve({
      logout: {
        success: true,
        errors: null,
        externalLogoutUrl: null,
      },
    })

    const authentication = authenticateStore()

    await authentication.logout()

    expect(authentication.authenticated).toBe(false)
    expect(useSessionStore().id).toBe(null)
  })

  it('cancels the running subscriptions during a logout', async () => {
    mockGraphQLApi(LogoutDocument).willResolve({
      logout: {
        success: true,
        errors: null,
        externalLogoutUrl: null,
      },
    })

    const authentication = authenticateStore()
    const teardownSpy = startTrackedSubscription()

    await authentication.logout()

    expect(teardownSpy).toHaveBeenCalledOnce()
    expect(authenticationInvalidated()).toBe(true)
  })

  it('cancels the running subscriptions when the authentication is cleared', async () => {
    const authentication = authenticateStore()
    const teardownSpy = startTrackedSubscription()

    await authentication.clearAuthentication()

    expect(teardownSpy).toHaveBeenCalledOnce()
    expect(authenticationInvalidated()).toBe(true)
  })

  it('clears the authentication even when the logout mutation fails', async () => {
    mockGraphQLApi(LogoutDocument).willFailWithNetworkError(new Error('Network error'))

    const authentication = authenticateStore()

    await expect(authentication.logout()).resolves.not.toThrow()

    // The client side of the session cannot be revived, so the user must not be
    //  left behind as authenticated.
    expect(authentication.authenticated).toBe(false)
    expect(useSessionStore().id).toBe(null)

    // The logout continues in any case, so its failure is nothing the user
    //  could act on.
    expect(useNotifications().notifications.value).toEqual([])
  })
})
