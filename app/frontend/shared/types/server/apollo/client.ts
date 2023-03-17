// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { FetchResult } from '@apollo/client/core'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import type { DocumentNode } from 'graphql'
import type { ImportGlobEagerOutput } from '../../utils'

export type RegisterInMemoryCacheConfig = (
  config: InMemoryCacheConfig,
) => InMemoryCacheConfig

export type CacheInitializerModules =
  ImportGlobEagerOutput<RegisterInMemoryCacheConfig>
export interface ClientErrorContext {
  logLevel: LogLevel
}

export interface DebugLinkRequestOutput {
  requestHeaders?: Record<string, string>
  printedDocument: string
  document: DocumentNode
  variables?: Record<string, unknown>
}

export interface DebugLinkResponseOutput {
  data: FetchResult
  responseHeaders?: Record<string, string>
}

export type InitializeAppApolloClient = (app: App) => void
