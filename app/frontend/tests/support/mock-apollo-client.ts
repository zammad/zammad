// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { provideApolloClient } from '@vue/apollo-composable'
import { InMemoryCache } from '@apollo/client/core'
import type { DocumentNode } from 'graphql'
import {
  createMockClient as createMockedClient,
  type MockApolloClient,
  type RequestHandler,
} from 'mock-apollo-client'

export interface ClientRequestHandler {
  operationDocument: DocumentNode
  handler: RequestHandler
}

let mockClient: Maybe<MockApolloClient>

afterEach(() => {
  mockClient = null
})

export const clearMockClient = () => {
  mockClient = null
}

const createMockClient = (
  handlers: ClientRequestHandler[],
  cacheOptions = {},
) => {
  if (!mockClient) {
    const cache = new InMemoryCache(cacheOptions)
    mockClient = createMockedClient({ cache })
  }

  handlers.forEach((clientRequestHandler) =>
    mockClient?.setRequestHandler(
      clientRequestHandler.operationDocument,
      clientRequestHandler.handler,
    ),
  )

  provideApolloClient(mockClient)

  return mockClient
}

export default createMockClient
