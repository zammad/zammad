// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, Observable } from '@apollo/client/core'
import { getMainDefinition } from '@apollo/client/utilities'

import log from '#shared/utils/log.ts'

import getSubscriptionContext from '../utils/getSubscriptionContext.ts'

import type { ObservableSubscription } from '@apollo/client/core'

const activeSubscriptions = new Set<ObservableSubscription>()

// Keeps track of all running GraphQL subscriptions, so that they can be
//  cancelled centrally before the authentication state is invalidated.
//
// On logout the web socket connection is reopened, because the GraphQL context
//  of a subscription - and with it the current user - is pinned when the
//  connection is established (see 'ApplicationCable::Connection'). Action Cable
//  resubscribes all of its still open channels afterwards and 'ActionCableLink'
//  re-executes the operation for each of them, which means every subscription
//  that is still running would be executed again on the now unauthenticated
//  connection and fail with an authentication error.
//
// Subscriptions which also work for unauthenticated users are excluded via the
//  'keepAliveOnLogout' subscription context, as they are needed on the login
//  screen as well.
const trackSubscriptionsLink = new ApolloLink((operation, forward) => {
  const definition = getMainDefinition(operation.query)

  if (definition.kind !== 'OperationDefinition' || definition.operation !== 'subscription') {
    return forward(operation)
  }

  if (getSubscriptionContext(operation).keepAliveOnLogout) return forward(operation)

  return new Observable((observer) => {
    const subscription = forward(operation).subscribe(observer)

    activeSubscriptions.add(subscription)

    return () => {
      activeSubscriptions.delete(subscription)
      subscription.unsubscribe()
    }
  })
})

export default trackSubscriptionsLink

// Cancels all running subscriptions, which also unsubscribes the related Action
//  Cable channels and therefore removes the subscriptions on the server side.
//
// This happens on the transport level only, so the composable which started a
//  subscription still considers itself running and will not resubscribe on its
//  own. That is fine for the logout, because everything that requires
//  authentication is unmounted or disposed as part of it anyway.
export const cancelActiveSubscriptions = (): void => {
  if (!activeSubscriptions.size) return

  log.debug(`[ActionCable] Cancelling ${activeSubscriptions.size} active subscription(s).`)

  activeSubscriptions.forEach((subscription) => subscription.unsubscribe())

  activeSubscriptions.clear()
}
