// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import {
  knowledgeBaseAnswerRoute,
  knowledgeBaseBrowseRoute,
} from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { LocationQuery, RouteLocationNamedRaw } from 'vue-router'

// The searched term, under the same name the browse page keeps it under
//   (useKnowledgeBaseSearchTerm), as it means the same thing here.
const TERM_PARAM = 'query'
// The searched scope: the browsed category's internal id, absent when the whole base
//   was searched from its root.
const SCOPE_PARAM = 'category'

interface SearchOrigin {
  term: string
  categoryId?: string
}

const firstParam = (value: LocationQuery[string]) =>
  (Array.isArray(value) ? value.at(-1) : value) ?? ''

// A search result's link: the answer, plus the search it was found in. The URL carries the
//   way back — as it carries the term on the browse page — so it survives a reload, a shared
//   link and opening a result in a new tab, and so it is absent when the same answer is
//   reached another way (breadcrumb, stepper, deep link), where there is no search to return to.
export const knowledgeBaseSearchResultRoute = (
  localeCode: string,
  answerId: string,
  { term, categoryId }: SearchOrigin,
): RouteLocationNamedRaw => ({
  ...knowledgeBaseAnswerRoute(localeCode, answerId),
  query: {
    [TERM_PARAM]: term,
    ...(categoryId ? { [SCOPE_PARAM]: String(getIdFromGraphQLId(categoryId)) } : {}),
  },
})

// The way back to the result list an answer was opened from, or undefined when it was not
//   opened from one.
export const knowledgeBaseSearchReturnRoute = (
  localeCode: string | undefined,
  query: LocationQuery,
): RouteLocationNamedRaw | undefined => {
  const term = firstParam(query[TERM_PARAM])

  if (!term) return undefined

  const scope = firstParam(query[SCOPE_PARAM])
  // Anything else was not written by a result link, and would not match the category route.
  const categoryId = /^\d+$/.test(scope)
    ? convertToGraphQLId('KnowledgeBase::Category', scope)
    : undefined

  return {
    ...knowledgeBaseBrowseRoute(localeCode, categoryId),
    query: { [TERM_PARAM]: term },
  }
}
