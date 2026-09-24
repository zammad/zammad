// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Subscriptions } from '#shared/graphql/types.ts'

import type { ImportGlobEagerOutput } from '../../utils.ts'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import type { FetchResult } from '@apollo/client/core'
import type { DocumentNode } from 'graphql'
import type { App } from 'vue'

export type RegisterInMemoryCacheConfig = (config: InMemoryCacheConfig) => InMemoryCacheConfig

export type CacheInitializerModules = ImportGlobEagerOutput<RegisterInMemoryCacheConfig>
export interface ClientErrorContext {
  logLevel: LogLevel
}

export interface ClientBatchContext {
  active: boolean
}

export interface ClientWebsocketContext {
  active: boolean
}

// Subscriptions whose updates for the changes of an operation are not sent back to the same browser tab,
//  e.g. because the operation result or the form already holds them.
export type ClientSkipSubscriptionsContext = Exclude<keyof Subscriptions, '__typename'>[]

export interface ClientSubscriptionContext {
  // Subscriptions which also work for unauthenticated users must survive the
  //  cleanup on logout, e.g. the config updates for the login screen.
  keepAliveOnLogout: boolean
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
