// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { RouteLocationNamedRaw } from 'vue-router'

// Clicking a tag hands the search a prepared term instead of a dedicated route
//   of its own.
// TODO: Add proper quick search handler for tag search when ready.
// TODO: The entity is pinned to tickets until the knowledge base is searchable
//   as its own entity.
export const tagSearchRoute = (tag: string): RouteLocationNamedRaw => ({
  name: 'Search',
  params: { searchTerm: `tags:"${tag}"` },
  query: { entity: 'Ticket' },
})
