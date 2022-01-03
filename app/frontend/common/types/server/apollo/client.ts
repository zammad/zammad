// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FetchResult } from '@apollo/client/core'
import type { DocumentNode } from 'graphql'

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
