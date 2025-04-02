// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumSearchableModels,
  Item,
  QuickSearchQuery,
} from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { PartialDeep } from 'type-fest'
import type { Component } from 'vue'

export type SearchPlugin = {
  name: EnumSearchableModels
  label: string
  priority: number // TODO I think we need two prios (because sorting is different in quick search and entity tabs in detail search)
  quickSearchResultLabel: string
  quickSearchComponent: Component
  quickSearchResultKey: Exclude<keyof QuickSearchQuery, '__typename'>
  permissions?: string[]
  show?: () => boolean
  detailSearchHeaders: string[]
  detailSearchComponent: Component
}

export interface QuickSearchPluginProps {
  item: ObjectLike
  mode: 'recently-viewed' | 'quick-search-results'
}

export interface QuickSearchResultData {
  component: Component
  remainingItemCount: number
  name: string
  label: string
  items: PartialDeep<Item>[]
  totalCount: number
}
