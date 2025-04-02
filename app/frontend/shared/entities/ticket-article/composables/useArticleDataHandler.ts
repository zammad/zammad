// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { noop } from 'lodash-es'
import { computed, type ComputedRef, nextTick, type Ref } from 'vue'

import { useTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.api.ts'
import { TicketArticleUpdatesDocument } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import type {
  PageInfo,
  TicketArticlesQuery,
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
  const firstArticlesCount = computed(
    () => options.firstArticlesCount?.value || 5,
  )

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

  const allArticleLoaded = computed(() => {
    if (!articleResult.value?.articles.totalCount) return false
    return (
      articleResult.value?.articles.edges.length <
      articleResult.value?.articles.totalCount
    )
  })

  const refetchArticlesQuery = (pageSize: Maybe<number>) => {
    articlesQuery.refetch({
      ticketId: ticketId.value,
      pageSize,
    })
  }

  const articleLoading = articlesQuery.loading()

  const isLoadingArticles = computed(() => {
    // Return already true when a article result already exists from the cache, also
    // when maybe a loading is in progress(because of cache + network).
    if (articleData.value !== undefined) return false

    return articleLoading.value
  })

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
      const prviousArticles =
        previousData?.articles as TicketArticlesQuery['articles']

      if (!prviousArticles || updates.updateArticle)
        return previousData as TicketArticlesQuery

      const previousArticlesEdges = prviousArticles.edges
      const previousArticlesEdgesCount = previousArticlesEdges.length

      if (updates.removeArticleId) {
        const edges = previousArticlesEdges.filter(
          (edge) => edge.node.id !== updates.removeArticleId,
        )

        const removedArticleVisible =
          edges.length !== previousArticlesEdgesCount

        if (removedArticleVisible && !allArticleLoaded.value) {
          refetchArticlesQuery(firstArticlesCount.value)

          return previousData as TicketArticlesQuery
        }

        const result = {
          ...previousData,
          articles: {
            ...prviousArticles,
            edges,
            totalCount: prviousArticles.totalCount - 1,
          },
        }

        if (removedArticleVisible) {
          const nextEndCursorEdge =
            previousArticlesEdges[previousArticlesEdgesCount - 2]

          result.articles.pageInfo = {
            ...prviousArticles.pageInfo,
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
    refetchArticlesQuery,
  }
}
