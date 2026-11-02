// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { provideApolloClient } from '@vue/apollo-composable/compat'
import {
  createMockClient as createMockedClient,
  type MockApolloClient,
  type RequestHandler,
} from 'mock-apollo-client'

import createCache from '#shared/server/apollo/cache.ts'
import type { CacheInitializerModules } from '#shared/types/server/apollo/client.ts'

import type { DocumentNode } from 'graphql'

const cacheInitializerModules: CacheInitializerModules = import.meta.glob(
  '../../mobile/server/apollo/cache/initializer/*.ts',
  { eager: true },
)

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

const createMockClient = (handlers: ClientRequestHandler[]) => {
  if (!mockClient) {
    const cache = createCache(cacheInitializerModules)
    mockClient = createMockedClient({
      cache,
      // The devtools-suggestion timer would fire after the jsdom window is gone.
      devtools: { enabled: false },
      // Version 1 stayed quiet about unmocked operations; specs rely on that.
      suppressMissingHandlerWarning: true,
    })
    provideApolloClient(mockClient)
  }

  handlers.forEach(({ operationDocument, handler }) => {
    try {
      mockClient?.setRequestHandler(operationDocument, handler)
    } catch {
      // A later, more specific mock replaces the one a suite registered before.
      mockClient?.removeRequestHandler(operationDocument)
      mockClient?.setRequestHandler(operationDocument, handler)
    }
  })

  return mockClient
}

export default createMockClient
