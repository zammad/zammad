// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloClient } from '@apollo/client'

import type { CacheInitializerModules } from '#shared/types/server/apollo/client.ts'

import createCache from './cache.ts'
import link from './link.ts'

let apolloClient: ApolloClient

export const createApolloClient = (cacheInitializerModules: CacheInitializerModules = {}) => {
  const cache = createCache(cacheInitializerModules)

  apolloClient = new ApolloClient({
    devtools: { enabled: process.env.NODE_ENV !== 'production' },
    link,
    cache,
    queryDeduplication: true,
    defaultOptions: {
      // always refresh query results from the server
      // https://www.apollographql.com/docs/react/data/queries/#setting-a-fetch-policy
      watchQuery: {
        fetchPolicy: 'cache-and-network',
        // No `nextFetchPolicy`: Apollo answers a cache update with a temporary "cache-first",
        //   which only reverts without one - returning the current policy would keep it for good.
      },
    },
  })

  return apolloClient
}

export const getApolloClient = () => {
  return apolloClient
}

// Lets the automocked test client stand in where `createApolloClient` never runs.
export const setApolloClient = (client: ApolloClient) => {
  apolloClient = client
}

export const clearApolloClientStore = async () => {
  await apolloClient.clearStore()
}
