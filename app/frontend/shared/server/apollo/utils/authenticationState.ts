// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operation } from '@apollo/client/core'

const OPERATION_CONTEXT_KEY = 'authenticationGeneration'

let invalidated = false

// Counts the authentications of this page load. Every change of the
//  authentication state starts a new generation, so that operations can be
//  attributed to the authentication they were sent with.
let generation = 0

// Remembers that the authentication is gone or on its way out, so that the
//  Apollo layer can tell an expected authentication error apart from a session
//  which just became invalid.
//
// Cancelling the running operations on logout is not enough to keep it quiet:
//  the views of the authenticated app stay mounted until the login screen is
//  reached, and clearing the Apollo store makes their reactive queries restart -
//  which starts a new query plus, via 'subscribeToMore', a new subscription that
//  cannot succeed anymore.
export const setAuthenticationInvalidated = (value: boolean): void => {
  if (value !== invalidated) generation += 1

  invalidated = value
}

export const authenticationInvalidated = (): boolean => invalidated

// Remembers on the operation which authentication it is being sent with.
export const rememberAuthenticationGeneration = (operation: Operation): void => {
  operation.setContext({ [OPERATION_CONTEXT_KEY]: generation })
}

// Tells whether the operation was sent with an authentication which is not the
//  current one anymore. Its result is a leftover of a past session, even if the
//  application is authenticated again in the meantime.
export const authenticationGenerationOutdated = (operation: Operation): boolean => {
  const operationGeneration = operation.getContext()[OPERATION_CONTEXT_KEY]

  return operationGeneration !== undefined && operationGeneration !== generation
}
