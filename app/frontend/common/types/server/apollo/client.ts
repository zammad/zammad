// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { FetchResult } from '@apollo/client/core'
import { DocumentNode } from 'graphql'

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
