// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumObjectManagerObjects,
  EnumSearchableModels,
  Item,
  QuickSearchQuery,
} from '#shared/graphql/types.ts'
import type { ConfigList } from '#shared/types/config.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { FilterSelectorEntry } from '../Form/fields/FieldFilterSelector/types'
import type { PartialDeep } from 'type-fest'
import type { Component } from 'vue'

/**
 * Overrides the default attributes for the filter selector.
 * It looks for the name key
 * ⚠️ We might undo this later directly on the object attributes
 * Intermediate solution until there
 */
export type FilterSelectorEntityOverride = Pick<FilterSelectorEntry, 'name' | 'label'>

export type SearchPlugin = {
  name: EnumSearchableModels
  object: EnumObjectManagerObjects
  label: string
  priority: number // TODO I think we need two prios (because sorting is different in quick search and entity tabs in detail search)
  quickSearchResultLabel: string
  quickSearchComponent: Component
  quickSearchResultKey: Exclude<keyof QuickSearchQuery, '__typename'>
  permissions?: string[]
  show?: () => boolean
  /**
   * Advanced-filter UI is enabled by default for users who can see the
   * entity (i.e. who satisfy `permissions`). These two opt-out hooks
   * override that:
   *  - `filtersDisabled: true` — no filter UI for this entity, ever.
   *  - `filterPermissions: [...]` — restrict to a narrower permission set
   *    than the entity's `permissions` (e.g. Ticket excludes
   *    `ticket.customer`).
   */
  filtersDisabled?: boolean
  filterPermissions?: string[]
  detailSearchHeaders: string[] | ((config: ConfigList) => string[])
  detailSearchComponent: Component
  filterAttributesOverride?: FilterSelectorEntityOverride[]
}

export interface QuickSearchPluginProps {
  item: ObjectLike
  mode: 'recently-closed' | 'quick-search-results'
}

export interface QuickSearchResultData {
  component: Component
  remainingItemCount: number
  name: string
  label: string
  items: PartialDeep<Item>[]
  totalCount: number
}
