// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { NormalizedCacheObject } from '@apollo/client/core'
import { ApolloClient } from '@apollo/client/core'
import type { CacheInitializerModules } from '@shared/types/server/apollo/client'
import link from './link'
import createCache from './cache'

let apolloClient: ApolloClient<NormalizedCacheObject>

export const createApolloClient = (
  cacheInitializerModules: CacheInitializerModules = {},
) => {
  const cache = createCache(cacheInitializerModules)

  apolloClient = new ApolloClient({
    connectToDevTools: process.env.NODE_ENV !== 'production',
    link,
    cache,
    queryDeduplication: true,
  })

  return apolloClient
}

export const getApolloClient = () => {
  return apolloClient
}

export const clearApolloClientStore = async () => {
  await apolloClient.clearStore()
}
