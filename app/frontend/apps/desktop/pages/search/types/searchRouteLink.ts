// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'

export interface SearchRouteQueryOptions {
  entity: string
  filters?: FilterSelectorEntry[]
  baseQuery?: Record<string, string>
}

export interface SearchDeepLinkOptions extends SearchRouteQueryOptions {
  searchTerm?: string
}
