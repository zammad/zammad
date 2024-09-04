<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, provide } from 'vue'

import {
  useArticleDataHandler,
  type AddArticleCallbackArgs,
} from '#shared/entities/ticket-article/composables/useArticleDataHandler.ts'
import { EnumTaskbarEntity } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'

import ArticleList from '../components/TicketDetailView/ArticleList.vue'
import TicketDetailTopBar from '../components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'
import TicketSidebar from '../components/TicketSidebar.vue'
import { ARTICLES_INFORMATION_KEY } from '../composables/useArticleContext.ts'
import {
  useProvideTicketInformation,
  useTicketInformation,
} from '../composables/useTicketInformation.ts'
import {
  useTicketSidebar,
  useProvideTicketSidebar,
} from '../composables/useTicketSidebar.ts'
import {
  type TicketSidebarContext,
  TicketSidebarScreenType,
} from '../types/sidebar.ts'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

useTaskbarTab(EnumTaskbarEntity.TicketZoom)

useProvideTicketInformation(toRef(props, 'internalId'))
const { ticket, ticketId } = useTicketInformation()

const onAddArticleCallback = ({ articlesQuery }: AddArticleCallbackArgs) => {
  return (articlesQuery as QueryHandler).refetch()
}

const { articleResult, articlesQuery, isLoadingArticles } =
  useArticleDataHandler(ticketId, { pageSize: 20, onAddArticleCallback })

provide(ARTICLES_INFORMATION_KEY, {
  articles: computed(() => articleResult.value),
  articlesQuery,
})

const sidebarContext = computed<TicketSidebarContext>(() => ({
  screenType: TicketSidebarScreenType.TicketDetailView,
  formValues: {
    // Workaround, to make the sidebars working for now.
    customer_id: ticket.value?.customer.internalId,
    organization_id: ticket.value?.organization?.internalId,
  },
}))

useProvideTicketSidebar(sidebarContext)
const { hasSidebar } = useTicketSidebar()
</script>

<template>
  <LayoutContent
    name="ticket-detail"
    no-padding
    background-variant="primary"
    :show-sidebar="hasSidebar"
    content-alignment="center"
  >
    <CommonLoader class="mt-8" :loading="!ticket">
      <div class="relative flex w-full flex-col">
        <TicketDetailTopBar />
        <ArticleList :aria-busy="isLoadingArticles" />
        <p>Tickt: <CommonLink link="/tickets/1">Testing 1</CommonLink></p>
      </div>
    </CommonLoader>

    <template #sideBar="{ isCollapsed, toggleCollapse }">
      <TicketSidebar
        :is-collapsed="isCollapsed"
        :toggle-collapse="toggleCollapse"
        :context="sidebarContext"
      />
    </template>
  </LayoutContent>
</template>
