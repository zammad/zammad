// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { noop } from 'lodash-es'
import { computed, type ComputedRef, nextTick, type Ref } from 'vue'

import { useTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.api.ts'
import { TicketArticleUpdatesDocument } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import type {
  PageInfo,
  TicketArticlesQuery,
  TicketArticlesQueryVariables,
  TicketArticleUpdatesSubscription,
  TicketArticleUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

export interface AddArticleCallbackArgs {
  updates: TicketArticleUpdatesSubscription['ticketArticleUpdates']
  previousArticlesEdges: TicketArticlesQuery['articles']['edges']
  previousArticlesEdgesCount: number
  articlesQuery: unknown // :TODO type this query sustainable
  result: Ref<TicketArticlesQuery | undefined>
  allArticleLoaded: ComputedRef<boolean>
  refetchArticlesQuery: (pageSize: Maybe<number>) => void
}

export const useArticleDataHandler = (
  ticketId: Ref<string>,
  options: {
    pageSize: number
    firstArticlesCount?: Ref<number>
    onAddArticleCallback?: (args: AddArticleCallbackArgs) => void
  } = {
    pageSize: 20,
  },
) => {
  const firstArticlesCount = computed(() => options.firstArticlesCount?.value || 5)

  const articlesQuery = new QueryHandler(
    useTicketArticlesQuery(
      () => ({
        ticketId: ticketId.value,
        pageSize: options.pageSize || 20,
        firstArticlesCount: firstArticlesCount.value,
      }),
      {
        context: {
          batch: {
            active: false,
          },
        },
      },
    ),
  )

  const articleResult = articlesQuery.result()

  const articleData = computed(() => articleResult.value)

  let previousArticleResult: TicketArticlesQuery | undefined
  const loadedArticleSelections = computed<TicketArticlesQueryVariables[]>((previousSelections) => {
    const previous = previousArticleResult
    const result = articleResult.value
    previousArticleResult = result
    const edges = result?.articles.edges
    if (!edges) return []

    const previousEdges = previous?.articles.edges ?? []
    const addedCount = edges.length - previousEdges.length
    const onlyOlderArticlesAdded =
      addedCount > 0 &&
      previousEdges.length > 0 &&
      previousSelections?.[0]?.ticketId === ticketId.value &&
      previousSelections[0].firstArticlesCount === firstArticlesCount.value &&
      previousEdges.every((edge, index) => edge === edges[index + addedCount]) &&
      previous?.firstArticles?.edges.length === result?.firstArticles?.edges.length &&
      previous?.firstArticles?.edges.every(
        (edge, index) => edge.node === result?.firstArticles?.edges[index]?.node,
      )

    // Anchor chunks at the newest end so fetching older articles preserves completed full pages.
    const pageSize = 2000
    const selections: TicketArticlesQueryVariables[] = []

    for (let offset = 0; offset < Math.max(edges.length, 1); offset += pageSize) {
      const end = edges.length - offset
      const previousSelection = onlyOlderArticlesAdded && previousSelections?.[selections.length]
      if (previousSelection && previousSelection.pageSize === pageSize) {
        selections.push(previousSelection)
        continue
      }

      selections.push({
        ticketId: ticketId.value,
        firstArticlesCount: firstArticlesCount.value,
        loadFirstArticles: offset === 0,
        pageSize: Math.min(pageSize, end),
        beforeCursor: edges[end]?.cursor,
      })
    }

    return selections
  })

  const allArticleLoaded = computed(() => {
    if (!articleResult.value?.articles.totalCount) return false
    return articleResult.value?.articles.edges.length < articleResult.value?.articles.totalCount
  })

  const refetchArticlesQuery = (pageSize: Maybe<number>) => {
    articlesQuery.refetch({
      ticketId: ticketId.value,
      pageSize,
    })
  }

  const isLoadingArticles = articlesQuery.loadingWithoutCachedResult()

  const adjustPageInfoAfterDeletion = (nextEndCursorEdge?: Maybe<string>) => {
    const newPageInfo: Pick<PageInfo, 'startCursor' | 'endCursor'> = {}

    if (nextEndCursorEdge) {
      newPageInfo.endCursor = nextEndCursorEdge
    } else {
      newPageInfo.startCursor = null
      newPageInfo.endCursor = null
    }

    return newPageInfo
  }

  articlesQuery.subscribeToMore<
    TicketArticleUpdatesSubscriptionVariables,
    TicketArticleUpdatesSubscription
  >(() => ({
    document: TicketArticleUpdatesDocument,
    variables: {
      ticketId: ticketId.value,
    },
    onError: noop,
    updateQuery(_, { previousData, subscriptionData }) {
      const updates = subscriptionData.data.ticketArticleUpdates
      const previousArticles = previousData?.articles as TicketArticlesQuery['articles']

      if (!previousArticles || updates.updateArticle) return previousData as TicketArticlesQuery

      const previousArticlesEdges = previousArticles.edges
      const previousArticlesEdgesCount = previousArticlesEdges.length

      if (updates.removeArticleId) {
        const edges = previousArticlesEdges.filter(
          (edge) => edge.node.id !== updates.removeArticleId,
        )

        const removedArticleVisible = edges.length !== previousArticlesEdgesCount

        if (removedArticleVisible && !allArticleLoaded.value) {
          refetchArticlesQuery(firstArticlesCount.value)

          return previousData as TicketArticlesQuery
        }

        const result = {
          ...previousData,
          articles: {
            ...previousArticles,
            edges,
            totalCount: previousArticles.totalCount - 1,
          },
        }

        if (removedArticleVisible) {
          const nextEndCursorEdge = previousArticlesEdges[previousArticlesEdgesCount - 2]

          result.articles.pageInfo = {
            ...previousArticles.pageInfo,
            ...adjustPageInfoAfterDeletion(nextEndCursorEdge.cursor),
          }
        }

        // Trigger cache garbage collection after the returned article deletion subscription
        //  updated the article list.
        nextTick(() => {
          getApolloClient().cache.gc()
        })

        return result
      }

      if (updates.addArticle) {
        options?.onAddArticleCallback?.({
          updates,
          previousArticlesEdges,
          previousArticlesEdgesCount,
          articlesQuery,
          result: articleResult,
          allArticleLoaded,
          refetchArticlesQuery,
        })
      }

      return previousData as TicketArticlesQuery
    },
  }))
  return {
    articlesQuery,
    articleResult,
    articleData,
    allArticleLoaded,
    isLoadingArticles,
    loadedArticleSelections,
    refetchArticlesQuery,
  }
}
