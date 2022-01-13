// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { provideApolloClient } from '@vue/apollo-composable'
import { InMemoryCache } from '@apollo/client/core'
import { DocumentNode } from 'graphql'
import {
  createMockClient as createMockedClient,
  RequestHandler,
} from 'mock-apollo-client'

interface ClientRequestHandler {
  operationDocument: DocumentNode
  handler: RequestHandler
}

const createMockClient = (
  handlers: ClientRequestHandler[],
  cacheOptions = {},
) => {
  const cache = new InMemoryCache(cacheOptions)

  const mockClient = createMockedClient({ cache })

  handlers.forEach((clientRequestHandler) =>
    mockClient.setRequestHandler(
      clientRequestHandler.operationDocument,
      clientRequestHandler.handler,
    ),
  )

  provideApolloClient(mockClient)

  return mockClient
}

export default createMockClient
