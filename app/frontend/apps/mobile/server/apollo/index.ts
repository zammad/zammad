// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import mainInitializeApolloClient from '@shared/server/apollo'
import type {
  InitializeAppApolloClient,
  CacheInitializerModules,
} from '@shared/types/server/apollo/client'
import { App } from 'vue'

const cacheInitializerModules: CacheInitializerModules = import.meta.globEager(
  './cache/initializer/*.ts',
)

const initializeApolloClient: InitializeAppApolloClient = (app: App) => {
  mainInitializeApolloClient(app, cacheInitializerModules)
}

export default initializeApolloClient
