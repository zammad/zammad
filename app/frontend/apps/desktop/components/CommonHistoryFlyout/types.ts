// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { HistoryRecordEvent } from '#shared/graphql/types.ts'

import type { Props } from './CommonHistoryFlyout.vue'
import type { DeepPartial } from 'ts-essentials'
import type { Component } from 'vue'

export type HistoryDescription = Omit<Props, 'name' | 'type'>

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
