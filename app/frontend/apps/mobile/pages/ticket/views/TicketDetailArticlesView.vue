<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useHeader } from '@mobile/composables/useHeader'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useApplicationStore } from '@shared/stores/application'
import { convertToGraphQLId } from '@shared/graphql/utils'
import type { TicketArticle } from '@shared/entities/ticket/types'
import { useTicketView } from '@shared/entities/ticket/composables/useTicketView'
import type {
  TicketArticleUpdatesSubscription,
  TicketArticleUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
import { noop } from 'lodash-es'
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

const articlesQuery = new QueryHandler(
  useTicketArticlesQuery(() => ({
    ticketId: convertToGraphQLId('Ticket', props.internalId),
    pageSize: Number(application.config.ticket_articles_min ?? 5),
  })),
  { errorShowNotification: false },
)

const result = articlesQuery.result()

articlesQuery.subscribeToMore<
  TicketArticleUpdatesSubscriptionVariables,
  TicketArticleUpdatesSubscription
>({
  document: TicketArticleUpdatesDocument,
  variables: {
    ticketId: convertToGraphQLId('Ticket', props.internalId),
  },
  onError: noop,
  updateQuery(previous, { subscriptionData }) {
    const updates = subscriptionData.data.ticketArticleUpdates
    if (updates.deletedArticleId) {
      const edges = previous.articles.edges.filter(
        (edge) => edge.node.id !== updates.deletedArticleId,
      )
      return {
        ...previous,
        articles: {
          ...previous.articles,
          edges,
          totalCount: previous.articles.totalCount - 1,
        },
      }
    }
    if (updates.createdArticle) {
      articlesQuery.fetchMore({
        variables: {
          pageSize: null,
          loadDescription: false,
          afterCursor: result.value?.articles.pageInfo.endCursor,
        },
      })
    }
    return previous
  },
})

const { ticket, liveUserList, ticketQuery } = useTicketInformation()
const { isTicketEditable } = useTicketView(ticket)

const isLoadingTicket = ticketQuery.loading()

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
      window.scrollTo({
        behavior: 'smooth',
        top: window.innerHeight,
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
</script>

<template>
  <div class="flex min-h-[calc(100vh_-_5rem)] flex-col pb-20">
    <TicketHeader
      :ticket="ticket"
      :live-user-list="liveUserList"
      :loading-ticket="isLoadingTicket"
    />
    <CommonLoader
      :loading="isLoadingTicket"
      data-test-id="loader-title"
      class="flex border-b-[0.5px] border-white/10 bg-gray-600/90 py-5 px-4"
    >
      <TicketTitle v-if="ticket" :ticket="ticket" />
    </CommonLoader>
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
  <TicketReplyButton v-if="isTicketEditable" />
</template>
