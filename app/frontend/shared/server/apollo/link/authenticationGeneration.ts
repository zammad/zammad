// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'

import { rememberAuthenticationGeneration } from '#shared/server/apollo/utils/authenticationState.ts'

// Tags every operation with the authentication it is sent with, so that a
//  response which only arrives after a logout and a new login can be told apart
//  from a failure of the current session.
const authenticationGenerationLink = new ApolloLink((operation, forward) => {
  rememberAuthenticationGeneration(operation)

  return forward(operation)
})

export default authenticationGenerationLink
