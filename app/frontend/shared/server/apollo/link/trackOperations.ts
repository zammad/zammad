// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, Observable } from '@apollo/client/core'
import { getMainDefinition } from '@apollo/client/utilities'

import log from '#shared/utils/log.ts'

import getSubscriptionContext from '../utils/getSubscriptionContext.ts'

import type { ObservableSubscription, Operation } from '@apollo/client/core'

const activeOperations = new Set<ObservableSubscription>()

// Mutations are never cancelled - the logout itself is one.
const isTrackedOperation = (operation: Operation) => {
  const definition = getMainDefinition(operation.query)

  if (definition.kind !== 'OperationDefinition') return false

  if (definition.operation === 'query') return true

  // Subscriptions which also work for unauthenticated users are excluded via the
  //  'keepAliveOnLogout' subscription context, as they are needed on the login
  //  screen as well.
  return (
    definition.operation === 'subscription' && !getSubscriptionContext(operation).keepAliveOnLogout
  )
}

// Keeps track of all running GraphQL queries and subscriptions, so that they can
//  be cancelled centrally before the authentication state is invalidated.
//
// On logout the web socket connection is reopened, because the GraphQL context
//  of a subscription - and with it the current user - is pinned when the
//  connection is established (see 'ApplicationCable::Connection'). Action Cable
//  resubscribes all of its still open channels afterwards and 'ActionCableLink'
//  re-executes the operation for each of them, which means every subscription
//  that is still running would be executed again on the now unauthenticated
//  connection and fail with an authentication error.
//
// Clearing the Apollo store cancels running queries as well, but only in a
//  following task: a result which arrives in between is still written into the
//  emptied cache and would show up in the next session.
const trackOperationsLink = new ApolloLink((operation, forward) => {
  if (!isTrackedOperation(operation)) return forward(operation)

  return new Observable((observer) => {
    const subscription = forward(operation).subscribe(observer)

    activeOperations.add(subscription)

    return () => {
      activeOperations.delete(subscription)
      subscription.unsubscribe()
    }
  })
})

export default trackOperationsLink

// Cancels all running queries and subscriptions on the transport level. This
//  aborts the HTTP requests of the queries, so that their results never reach
//  the Apollo cache, and unsubscribes the related Action Cable channels, which
//  removes the subscriptions on the server side.
//
// The composable which started an operation still considers it running. That
//  is fine for the logout, because everything that requires authentication is
//  unmounted or disposed as part of it anyway, and clearing the Apollo store
//  rejects the cancelled queries as usual.
export const cancelActiveOperations = (): void => {
  if (!activeOperations.size) return

  log.debug(`[Apollo] Cancelling ${activeOperations.size} active operation(s).`)

  activeOperations.forEach((subscription) => subscription.unsubscribe())

  activeOperations.clear()
}
