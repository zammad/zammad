// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import type { RouteLocationNamedRaw } from 'vue-router'

// The knowledge base root listing and a single category are two separate routes
//   — a category carries `/category/:id` in the URL (mirroring the `/answer/:id`
//   route added later). This picks the right target from what a caller has, so
//   callers don't juggle the two route names and params themselves. Omitting the
//   locale targets the section entry, whose guard resolves the user's preferred
//   locale (falling back to the primary, or not-found when there is none).
export const knowledgeBaseBrowseRoute = (
  localeCode?: string,
  categoryId?: string,
): RouteLocationNamedRaw => {
  if (localeCode && categoryId) {
    return {
      name: 'KnowledgeBaseCategory',
      // Use the internal id in the URL; the GraphQL global id would be
      //   percent-encoded into an unreadable path segment.
      params: { localeCode, categoryInternalId: getIdFromGraphQLId(categoryId) },
    }
  }

  return { name: 'KnowledgeBaseBrowse', params: localeCode ? { localeCode } : {} }
}
