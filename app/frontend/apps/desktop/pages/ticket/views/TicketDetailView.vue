<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, provide } from 'vue'

import {
  type AddArticleCallbackArgs,
  useArticleDataHandler,
} from '#shared/entities/ticket-article/composables/useArticleDataHandler.ts'
import { useTicketDataHandler } from '#shared/entities/ticket-article/composables/useTicketDataHandler.ts'
import { EnumTaskbarEntity } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import ArticleList from '#desktop/pages/ticket/components/TicketDetailView/ArticleList.vue'
import TicketDetailTopBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'
import { ARTICLES_INFORMATION_KEY } from '#desktop/pages/ticket/composables/useArticleContext.ts'
import { TICKET_INFORMATION_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

useTaskbarTab(EnumTaskbarEntity.TicketZoom)

const ticketId = computed(() => convertToGraphQLId('Ticket', props.internalId))

const { ticketResult, isLoadingTicket } = useTicketDataHandler(ticketId)

provide(
  TICKET_INFORMATION_KEY,
  computed(() => ticketResult.value?.ticket),
)

const onAddArticleCallback = ({ articlesQuery }: AddArticleCallbackArgs) => {
  return (articlesQuery as QueryHandler).refetch()
}

const { articleResult, articlesQuery, isLoadingArticles } =
  useArticleDataHandler(ticketId, { pageSize: 20, onAddArticleCallback })

provide(ARTICLES_INFORMATION_KEY, {
  articles: computed(() => articleResult.value),
  articlesQuery,
})
</script>

<template>
  <LayoutContent
    name="ticket-create"
    no-padding
    background-variant="primary"
    content-alignment="center"
  >
    <CommonLoader class="mt-8" :loading="isLoadingTicket">
      <div class="relative flex w-full flex-col">
        <TicketDetailTopBar />

        <ArticleList role="feed" :aria-busy="isLoadingArticles.value" />
      </div>
    </CommonLoader>
  </LayoutContent>
</template>
