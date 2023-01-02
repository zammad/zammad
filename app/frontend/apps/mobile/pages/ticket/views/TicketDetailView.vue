<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useHeader } from '@mobile/composables/useHeader'
import { computed, watch } from 'vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useRouter } from 'vue-router'
import { useApplicationStore } from '@shared/stores/application'
import { useSessionStore } from '@shared/stores/session'
import { ErrorStatusCodes } from '@shared/types/error'
import { whenever } from '@vueuse/shared'
import type {
  TicketUpdatesSubscription,
  TicketUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
import { redirectToError } from '@mobile/router/error'
import TicketHeader from '../components/TicketDetailView/TicketDetailViewHeader.vue'
import TicketTitle from '../components/TicketDetailView/TicketDetailViewTitle.vue'
import { useTicketQuery } from '../graphql/queries/ticket.api'
import TicketArticlesList from '../components/TicketDetailView/ArticlesList.vue'
import TicketReplyButton from '../components/TicketDetailView/TicketDetailViewReplyButton.vue'
import { useTicketArticlesQuery } from '../graphql/queries/ticket/articles.api'
import type { TicketArticle } from '../types/tickets'
import { TicketUpdatesDocument } from '../graphql/subscriptions/ticketUpdates.api'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const ticketQuery = new QueryHandler(
  useTicketQuery(() => ({
    ticketInternalId: Number(props.internalId),
  })),
  { errorShowNotification: false },
)

const session = useSessionStore()
const application = useApplicationStore()

const articlesQuery = new QueryHandler(
  useTicketArticlesQuery(() => ({
    ticketInternalId: Number(props.internalId),
    pageSize: Number(application.config.ticket_articles_min ?? 5),
    isAgent: session.hasPermission(['ticket.agent']),
  })),
  { errorShowNotification: false },
)

const router = useRouter()

ticketQuery.onError(() => {
  return redirectToError(router, {
    statusCode: ErrorStatusCodes.Forbidden,
    message: __('Sorry, but you have insufficient rights to open this page.'),
  })
})

const isLoadingTicket = ticketQuery.loading()

const ticket = computed(() => ticketQuery.result().value?.ticket)
const result = articlesQuery.result()

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

const stopWatch = whenever(
  () => !isLoadingTicket.value,
  () => {
    if (!ticket.value) return

    stopWatch()

    ticketQuery.subscribeToMore<
      TicketUpdatesSubscriptionVariables,
      TicketUpdatesSubscription
    >({
      document: TicketUpdatesDocument,
      variables: {
        ticketId: ticket.value.id,
      },
    })
  },
)

// TODO get users from graphql
const users = [{ id: '1' }, { id: '2', lastname: 'Smith', firstname: 'John' }]
// const usersLoading = ref(true) // TODO

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
      cursor: result.value?.articles.pageInfo.startCursor,
    },
  })
}
</script>

<template>
  <div class="flex min-h-[calc(100vh_-_5rem)] flex-col pb-20">
    <TicketHeader
      :ticket-id="ticket?.number || ''"
      :created-at="ticket?.createdAt || ''"
      :users="users"
      :loading-ticket="isLoadingTicket"
      :loading-users="isLoadingTicket"
    />
    <CommonLoader
      :loading="isLoadingTicket"
      center
      data-test-id="loader-title"
      class="flex border-b-[0.5px] border-white/10 bg-gray-600/90 py-5 px-4"
    >
      <TicketTitle v-if="ticket" :ticket="ticket" />
    </CommonLoader>
    <CommonLoader
      data-test-id="loader-list"
      :loading="isLoadingTicket"
      center
      class="mt-2"
    >
      <TicketArticlesList
        :ticket-internal-id="Number(internalId)"
        :articles="articles"
        :total-count="totalCount"
        @load-previous="loadPreviousArticles"
      />
    </CommonLoader>
  </div>
  <TicketReplyButton />
</template>
