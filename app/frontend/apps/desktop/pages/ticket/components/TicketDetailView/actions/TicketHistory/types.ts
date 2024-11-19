// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { HistoryRecordEvent } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import type { Component } from 'vue'

export interface EventActionContent {
  description?: string | null
  entityName?: string | null
  attributeName?: string | null
  details?: string | null
  additionalDetails?: string | null
  showSeparator?: boolean | null
  link?: string | null
}

export interface EventActionOutput extends EventActionContent {
  actionName: string
  component?: Component
}

export type EventActionModule = {
  name: string
  content: (event: DeepPartial<HistoryRecordEvent>) => EventActionContent
  component?: Component
  actionName: string | ((event: DeepPartial<HistoryRecordEvent>) => string)
}
