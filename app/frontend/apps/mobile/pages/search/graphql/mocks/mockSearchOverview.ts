// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { SearchQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake, DeepPartial } from '#shared/types/utils.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { nullableMock } from '#tests/support/utils.ts'
import { SearchDocument } from '../queries/searchOverview.api.ts'

type SearchResult = ConfidentTake<SearchQuery, 'search'>

export const mockSearchOverview = (search: DeepPartial<SearchResult>) => {
  return mockGraphQLApi(SearchDocument).willResolve(
    nullableMock<SearchQuery>({
      search: {
        __typename: 'SearchResult',
        ...search,
      },
    }),
  )
}
