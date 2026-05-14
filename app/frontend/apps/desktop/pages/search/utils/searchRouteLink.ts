// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { stringifyQuery } from 'vue-router'

import { encodeFilters } from './searchFilterQuery.ts'

import type { SearchDeepLinkOptions, SearchRouteQueryOptions } from '../types/searchRouteLink.ts'

export const buildSearchRouteQuery = ({
  entity,
  filters = [],
  baseQuery = {},
}: SearchRouteQueryOptions): Record<string, string> => ({
  ...baseQuery,
  entity,
  ...encodeFilters(filters),
})

export const buildSearchDeepLink = ({
  searchTerm = '',
  entity,
  filters = [],
  baseQuery = {},
}: SearchDeepLinkOptions): string => {
  const queryString = stringifyQuery(buildSearchRouteQuery({ entity, filters, baseQuery }))

  return `/search/${encodeURIComponent(searchTerm)}${queryString ? `?${queryString}` : ''}`
}
