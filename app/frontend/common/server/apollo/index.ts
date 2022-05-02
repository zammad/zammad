// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createApolloClient } from '@common/server/apollo/client'
import {
  DefaultApolloClient,
  provideApolloClient,
} from '@vue/apollo-composable'
import type { CacheInitializerModules } from '@common/types/server/apollo/client'
import type { App } from 'vue'

const initializeApolloClient = (
  app: App,
  cacheInitializerModules: CacheInitializerModules = {},
) => {
  const apolloClient = createApolloClient(cacheInitializerModules)

  app.provide(DefaultApolloClient, apolloClient)

  provideApolloClient(apolloClient)
}

export default initializeApolloClient
