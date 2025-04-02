// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type {
  DetailSearchQuery,
  DetailSearchQueryVariables,
} from '#shared/graphql/types'
import { getApolloClient } from '#shared/server/apollo/client.ts'

import { DetailSearchDocument } from '#desktop/components/Search/graphql/queries/detailSearch.api.ts'

export const useDetailSearchCache = () => {
  const apolloClient = getApolloClient()

  const readDetailSearchCache = (variables: DetailSearchQueryVariables) => {
    return apolloClient.readQuery<
      DetailSearchQuery,
      DetailSearchQueryVariables
    >({
      query: DetailSearchDocument,
      variables,
    })
  }

  const writeDetailSearchCache = (
    variables: DetailSearchQueryVariables,
    data: DetailSearchQuery,
  ) => {
    return apolloClient.writeQuery<DetailSearchQuery>({
      query: DetailSearchDocument,
      variables,
      data,
    })
  }

  const forceDetailSearchCacheOnlyFirstPage = (
    variables: DetailSearchQueryVariables,
    pageSize: number,
  ) => {
    const currentDetailSearch = readDetailSearchCache(variables)

    if (!currentDetailSearch) return

    const currentItems = currentDetailSearch?.search?.items

    const currentItemsCount = currentItems?.length

    if (!currentItemsCount || currentItemsCount <= pageSize) return

    const slicedItems = currentItems?.slice(0, pageSize)

    writeDetailSearchCache(variables, {
      search: {
        ...currentDetailSearch.search,
        items: slicedItems,
      },
    })
  }

  return {
    readDetailSearchCache,
    writeDetailSearchCache,
    forceDetailSearchCacheOnlyFirstPage,
  }
}
