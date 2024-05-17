// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'

import { recordCommunicationSuccess } from '#shared/server/connection.ts'

// This link is only there to look for received responses and set
//  the applicationConnected state accordingly.
const connectedStateLink = new ApolloLink((operation, forward) => {
  return forward(operation).map((response) => {
    // A response in this chain means there was no network error.
    recordCommunicationSuccess()
    return response
  })
})

export default connectedStateLink
