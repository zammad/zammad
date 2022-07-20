<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useHeader } from '@mobile/composables/useHeader'
import { computed } from 'vue'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { QueryHandler } from '@shared/server/apollo/handler'
import TicketZoomHeader from '../components/TicketZoom/TicketZoomHeader.vue'
import TicketZoomTitle from '../components/TicketZoom/TicketZoomTitle.vue'
import { useTicketQuery } from '../graphql/queries/ticket.api'
import TicketZoomArticlesList from '../components/TicketZoom/ArticlesList.vue'
import TicketZoomReplyButton from '../components/TicketZoom/TicketZoomReplyButton.vue'
import type { TicketArticle } from '../types/tickets'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const ticketQuery = new QueryHandler(
  useTicketQuery(() => ({
    ticketInternalId: Number(props.internalId),
    withArticles: true,
  })),
  {
    errorNotificationMessage: __('Could not load the ticket'),
  },
)

const isLoadingTicket = ticketQuery.loading()
const ticketsError = ticketQuery.operationError()

const ticket = computed(() => ticketQuery.result().value?.ticket)
const articles = computed(() =>
  (
    (ticket.value?.articles?.edges.map(({ node }) => node).filter(Boolean) ||
      []) as TicketArticle[]
  ).sort(
    (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
  ),
)

useHeader({
  title: computed(() => {
    if (!ticket.value) return ''
    const { number, title } = ticket.value
    return `#${number} - ${title}`
  }),
})

// TODO get users from graphql
const users = [{ id: '1' }, { id: '2', lastname: 'Smith', firstname: 'John' }]
// const usersLoading = ref(true) // TODO
</script>

<template>
  <div class="flex min-h-[calc(100vh_-_5rem)] flex-col pb-20">
    <TicketZoomHeader
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
      <TicketZoomTitle v-if="ticket" :ticket="ticket" />
    </CommonLoader>
    <CommonLoader
      :error="ticketsError?.message"
      data-test-id="loader-list"
      :loading="isLoadingTicket"
      center
      class="mt-2"
    >
      <TicketZoomArticlesList :articles="articles" />
    </CommonLoader>
  </div>
  <TicketZoomReplyButton />
</template>
