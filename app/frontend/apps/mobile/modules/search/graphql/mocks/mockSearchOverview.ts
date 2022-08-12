// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { SearchQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { SearchDocument } from '../searchOverview.api'

export const mockSearchOverview = (
  search: ConfidentTake<SearchQuery, 'search'>,
) => {
  return mockGraphQLApi(SearchDocument).willResolve({
    search,
  })
}
