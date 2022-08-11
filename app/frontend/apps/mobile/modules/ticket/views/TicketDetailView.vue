<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useHeader } from '@mobile/composables/useHeader'
import { computed } from 'vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useRouter } from 'vue-router'
import { isNonNullObject } from '@apollo/client/utilities'
import { useSessionStore } from '@shared/stores/session'
import { ErrorStatusCodes } from '@shared/types/error'
import { whenever } from '@vueuse/shared'
import type {
  TicketUpdatesSubscription,
  TicketUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
import TicketHeader from '../components/TicketDetailView/TicketDetailViewHeader.vue'
import TicketTitle from '../components/TicketDetailView/TicketDetailViewTitle.vue'
import { useTicketQuery } from '../graphql/queries/ticket.api'
import TicketArticlesList from '../components/TicketDetailView/ArticlesList.vue'
import TicketReplyButton from '../components/TicketDetailView/TicketDetailViewReplyButton.vue'
import { useTicketArticlesQuery } from '../graphql/queries/ticket/articles.api'
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

const articlesQuery = new QueryHandler(
  useTicketArticlesQuery(() => ({
    ticketInternalId: Number(props.internalId),
    isAgent: session.hasPermission(['admin.*', 'ticket.agent']),
  })),
  { errorShowNotification: false },
)

const router = useRouter()

ticketQuery.onError(() => {
  return router.replace({
    name: 'Error',
    params: {
      statusCode: ErrorStatusCodes.Forbidden,
      message: __('Sorry, but you have insufficient rights to open this page.'),
    },
  })
})

const isLoadingTicket = ticketQuery.loading()

const ticket = computed(() => ticketQuery.result().value?.ticket)

const toMs = (date: string) => new Date(date).getTime()
const articles = computed(() => {
  const result = articlesQuery.result()
  const nodes = result.value?.ticketArticles.edges.map(({ node }) => node) || []
  return nodes
    .filter(isNonNullObject)
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
      />
    </CommonLoader>
  </div>
  <TicketReplyButton />
</template>
