<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch, nextTick } from 'vue'
import { noop } from 'lodash-es'
import { useHeader } from '@mobile/composables/useHeader'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useApplicationStore } from '@shared/stores/application'
import { convertToGraphQLId } from '@shared/graphql/utils'
import type { TicketArticle } from '@shared/entities/ticket/types'
import { useTicketView } from '@shared/entities/ticket/composables/useTicketView'
import type {
  PageInfo,
  TicketArticleUpdatesSubscription,
  TicketArticleUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
import { getApolloClient } from '@shared/server/apollo/client'
import { useStickyHeader } from '@shared/composables/useStickyHeader'
import TicketHeader from '../components/TicketDetailView/TicketDetailViewHeader.vue'
import TicketTitle from '../components/TicketDetailView/TicketDetailViewTitle.vue'
import TicketArticlesList from '../components/TicketDetailView/ArticlesList.vue'
import TicketReplyButton from '../components/TicketDetailView/TicketDetailViewReplyButton.vue'
import { useTicketArticlesQuery } from '../graphql/queries/ticket/articles.api'
import { useTicketInformation } from '../composable/useTicketInformation'
import { TicketArticleUpdatesDocument } from '../graphql/subscriptions/ticketArticlesUpdates.api'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const application = useApplicationStore()

const ticketId = computed(() => convertToGraphQLId('Ticket', props.internalId))

const ticketArticlesMin = computed(() => {
  return Number(application.config.ticket_articles_min ?? 5)
})

const articlesQuery = new QueryHandler(
  useTicketArticlesQuery(() => ({
    ticketId: ticketId.value,
    pageSize: ticketArticlesMin.value,
  })),
  { errorShowNotification: false },
)

const result = articlesQuery.result()

const allArticleLoaded = computed(() => {
  if (!result.value?.articles.totalCount) return false
  return result.value?.articles.edges.length < result.value?.articles.totalCount
})

const refetchArticlesQuery = (pageSize: Maybe<number>) => {
  articlesQuery.refetch({
    ticketId: ticketId.value,
    pageSize,
  })
}

// When the last article is deleted, cursor has to be adjusted
//  to show newly created articles in the list (if any).
// Cursor is offset-based, so the old cursor is pointing to an unavailable article,
//  thus using the cursor for the last article of the already filtered edges.
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
  updateQuery(previous, { subscriptionData }) {
    const updates = subscriptionData.data.ticketArticleUpdates

    if (!previous.articles || updates.updateArticle) return previous

    const previousArticlesEdges = previous.articles.edges
    const previousArticlesEdgesCount = previousArticlesEdges.length

    if (updates.removeArticleId) {
      const edges = previousArticlesEdges.filter(
        (edge) => edge.node.id !== updates.removeArticleId,
      )

      const removedArticleVisible = edges.length !== previousArticlesEdgesCount

      if (removedArticleVisible && !allArticleLoaded.value) {
        refetchArticlesQuery(ticketArticlesMin.value)

        return previous
      }

      const result = {
        ...previous,
        articles: {
          ...previous.articles,
          edges,
          totalCount: previous.articles.totalCount - 1,
        },
      }

      if (removedArticleVisible) {
        const nextEndCursorEdge =
          previousArticlesEdges[previousArticlesEdgesCount - 2]

        result.articles.pageInfo = {
          ...previous.articles.pageInfo,
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
      const needRefetch =
        !previousArticlesEdges[previousArticlesEdgesCount - 1] ||
        updates.addArticle.createdAt <=
          previousArticlesEdges[previousArticlesEdgesCount - 1].node.createdAt

      if (!allArticleLoaded.value || needRefetch) {
        refetchArticlesQuery(null)
      } else {
        articlesQuery.fetchMore({
          variables: {
            pageSize: null,
            loadDescription: false,
            afterCursor: result.value?.articles.pageInfo.endCursor,
          },
        })
      }
    }
    return previous
  },
}))

const { ticket, liveUserList, ticketQuery } = useTicketInformation()
const { isTicketEditable } = useTicketView(ticket)

const isLoadingTicket = computed(() => {
  return ticketQuery.loading().value && !ticket.value
})

const isRefetchingTicket = computed(
  () => ticketQuery.loading().value && !!ticket.value,
)

const totalCount = computed(() => result.value?.articles.totalCount || 0)

const toMs = (date: string) => new Date(date).getTime()
const articles = computed(() => {
  if (!result.value) {
    return []
  }
  const nodes = result.value.articles.edges.map(({ node }) => node) || []
  const totalCount = result.value.articles.totalCount || 0
  // description might've returned with "articles"
  const description = result.value.description.edges[0]?.node
  if (totalCount > nodes.length && description) {
    nodes.unshift(description)
  }
  return nodes
    .filter((a): a is TicketArticle => a != null)
    .sort((a, b) => toMs(a.createdAt) - toMs(b.createdAt))
})

useHeader({
  title: computed(() => {
    if (!ticket.value) return ''
    const { number, title } = ticket.value
    return `#${number} - ${title}`
  }),
})

watch(
  () => articles.value.length,
  (length) => {
    if (!length) return

    requestAnimationFrame(() => {
      const lastArticle = document.querySelector(
        `#article-${articles.value[length - 1].internalId}`,
      ) as HTMLElement | null
      if (!lastArticle) return
      window.scrollTo({
        behavior: 'smooth',
        top: lastArticle.offsetTop,
      })
    })
  },
  { immediate: true },
)

const loadPreviousArticles = async () => {
  await articlesQuery.fetchMore({
    variables: {
      pageSize: null,
      loadDescription: false,
      beforeCursor: result.value?.articles.pageInfo.startCursor,
    },
  })
}

const { stickyStyles, headerElement } = useStickyHeader([
  isLoadingTicket,
  ticket,
])
</script>

<template>
  <div
    id="ticket-header"
    ref="headerElement"
    class="relative backdrop-blur-lg"
    :style="stickyStyles.header"
  >
    <TicketHeader
      :ticket="ticket"
      :live-user-list="liveUserList"
      :loading-ticket="isLoadingTicket"
      :refetching-ticket="isRefetchingTicket"
    />
    <CommonLoader
      :loading="isLoadingTicket"
      data-test-id="loader-title"
      class="flex border-b-[0.5px] border-white/10 bg-gray-600/90 py-5 px-4"
    >
      <TicketTitle v-if="ticket" :ticket="ticket" />
    </CommonLoader>
  </div>
  <div class="flex flex-1 flex-col pb-safe-20" :style="stickyStyles.body">
    <CommonLoader
      data-test-id="loader-list"
      :loading="isLoadingTicket"
      class="mt-2"
    >
      <TicketArticlesList
        v-if="ticket"
        :ticket="ticket"
        :articles="articles"
        :total-count="totalCount"
        @load-previous="loadPreviousArticles"
      />
    </CommonLoader>
  </div>
  <TicketReplyButton v-if="isTicketEditable" class="z-10" />
</template>
