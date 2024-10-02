<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEventListener } from '@vueuse/core'
import { computed, watch } from 'vue'
import { useRoute } from 'vue-router'

import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'
import {
  type AddArticleCallbackArgs,
  useArticleDataHandler,
} from '#shared/entities/ticket-article/composables/useArticleDataHandler.ts'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { edgesToArray, waitForElement } from '#shared/utils/helpers.ts'

import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import { useHeader } from '#mobile/composables/useHeader.ts'

import TicketArticlesList from '../components/TicketDetailView/ArticlesList.vue'
import TicketHeader from '../components/TicketDetailView/TicketDetailViewHeader.vue'
import TicketTitle from '../components/TicketDetailView/TicketDetailViewTitle.vue'
import { useTicketArticlesQueryVariables } from '../composable/useTicketArticlesVariables.ts'
import { useTicketInformation } from '../composable/useTicketInformation.ts'

interface Props {
  internalId: string
}

const props = defineProps<Props>()

const ticketId = computed(() => convertToGraphQLId('Ticket', props.internalId))

// When the last article is deleted, cursor has to be adjusted
//  to show newly created articles in the list (if any).
// Cursor is offset-based, so the old cursor is pointing to an unavailable article,
//  thus using the cursor for the last article of the already filtered edges.

const {
  ticket,
  liveUserList,
  ticketQuery,
  scrolledToBottom,
  newArticlesIds,
  scrollDownState,
} = useTicketInformation()

const scrollElement = (element: Element) => {
  scrolledToBottom.value = true
  element.scrollIntoView({ behavior: 'smooth', block: 'start' })
  return true
}

const session = useSessionStore()

const scheduleMyArticleScroll = async (
  articleInternalId: number,
  originalTime = new Date().getTime(),
): Promise<void> => {
  // try to scroll for 5 seconds
  const difference = new Date().getTime() - originalTime
  if (difference >= 5000 || typeof document === 'undefined') return

  const element = document.querySelector(
    `#article-${articleInternalId}`,
  ) as HTMLDivElement | null

  if (!element) {
    return new Promise((r) => requestAnimationFrame(r)).then(() =>
      scheduleMyArticleScroll(articleInternalId, originalTime),
    )
  }

  if (element.dataset.createdBy === session.userId) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
}

const isAtTheBottom = () => {
  const scrollHeight =
    document.querySelector('main')?.scrollHeight || window.innerHeight
  const scrolledHeight = window.scrollY + window.innerHeight
  const scrollToBottom = scrollHeight - scrolledHeight
  return scrollToBottom < 20
}

const hasScroll = () => {
  const scrollHeight =
    document.querySelector('main')?.scrollHeight || window.innerHeight
  return scrollHeight > window.innerHeight
}

const onAddArticleCallback = ({
  updates,
  previousArticlesEdges,
  previousArticlesEdgesCount,
  articlesQuery,
  result,
  allArticleLoaded,
  refetchArticlesQuery,
}: AddArticleCallbackArgs) => {
  scrollDownState.value = hasScroll()
  newArticlesIds.add(updates?.addArticle?.id as string)
  scheduleMyArticleScroll(getIdFromGraphQLId(updates?.addArticle?.id as string))

  const needRefetch =
    !previousArticlesEdges[previousArticlesEdgesCount - 1] ||
    (updates?.addArticle?.createdAt as string) <=
      previousArticlesEdges[previousArticlesEdgesCount - 1].node.createdAt

  if (!allArticleLoaded.value || needRefetch) {
    refetchArticlesQuery(null)
  } else {
    ;(articlesQuery as QueryHandler).fetchMore({
      variables: {
        pageSize: 100,
        loadFirstArticles: false,
        afterCursor: result.value?.articles.pageInfo.endCursor,
      },
    })
  }
}

const {
  ticketArticlesMin,
  markTicketArticlesLoaded,
  getTicketArticlesQueryVariables,
} = useTicketArticlesQueryVariables()

const { articlesQuery, articleResult } = useArticleDataHandler(ticketId, {
  firstArticlesCount: ticketArticlesMin,
  pageSize: getTicketArticlesQueryVariables(ticketId.value).pageSize as number,
  onAddArticleCallback,
})

const loadPreviousArticles = async () => {
  markTicketArticlesLoaded(ticketId.value)
  await articlesQuery.fetchMore({
    variables: {
      pageSize: 100,
      loadFirstArticles: false,
      beforeCursor: articleResult.value?.articles.pageInfo.startCursor,
    },
  })
}

const isLoadingTicket = computed(() => {
  return ticketQuery.loading().value && !ticket.value
})

const isRefetchingTicket = computed(
  () => ticketQuery.loading().value && !!ticket.value,
)

const totalCount = computed(() => articleResult.value?.articles.totalCount || 0)

const toMs = (date: string) => new Date(date).getTime()

const articles = computed(() => {
  if (!articleResult.value) {
    return []
  }
  const nodes = edgesToArray(articleResult.value.articles)
  const totalCount = articleResult.value.articles.totalCount || 0
  // description might've returned with "articles"
  const description = articleResult.value.firstArticles?.edges[0]?.node
  if (totalCount > nodes.length && description) {
    nodes.unshift(description)
  }
  return nodes.sort((a, b) => toMs(a.createdAt) - toMs(b.createdAt))
})

useHeader({
  title: computed(() => {
    if (!ticket.value) return ''
    const { number, title } = ticket.value
    return `#${number} - ${title}`
  }),
})

// don't scroll only if articles are already loaded when you opened the page
// and there is a saved scroll position
// otherwise if we only check the scroll position we will never scroll to the bottom
// because it can be defined when we open the page the first time
if (articleResult.value && window.history?.state?.scroll) {
  scrolledToBottom.value = true
}

const route = useRoute()

let ignoreQuery = false

// scroll to the article in the hash or to the last available article
const initialScroll = async () => {
  if (route.hash) {
    const articleNode = document.querySelector(route.hash)

    if (articleNode) {
      return scrollElement(articleNode)
    }

    if (!articleNode && !ignoreQuery) {
      ignoreQuery = true
      await loadPreviousArticles()
      const node = document.querySelector(route.hash)
      if (node) {
        return scrollElement(node)
      }
    }
  }

  const internalId = articles.value[articles.value.length - 1]?.internalId
  if (!internalId) return false

  const lastArticle = await waitForElement(`#article-${internalId}`)

  if (!lastArticle) return false

  return scrollElement(lastArticle)
}

const stopScrollWatch = watch(
  () => articles.value.length,
  async () => {
    // Do nothing for initial article computed value, because this is initialy an empty error, when
    // nothing is used from the cache.
    if (articles.value.length === 0) return

    if (hasScroll() && !isAtTheBottom()) {
      scrollDownState.value = true
    }

    const scrolled = await initialScroll()
    if (scrolled) stopScrollWatch()
  },
  { immediate: true, flush: 'post' },
)

const { stickyStyles, headerElement } = useStickyHeader([
  isLoadingTicket,
  ticket,
])

useEventListener(
  window.document,
  'scroll',
  () => {
    scrollDownState.value = !isAtTheBottom()
  },
  { passive: true },
)
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
      class="flex border-b-[0.5px] border-white/10 bg-gray-600/90 px-4 py-5"
    >
      <TicketTitle v-if="ticket" :ticket="ticket" />
    </CommonLoader>
  </div>
  <div
    id="ticket-articles-list"
    class="flex flex-1 flex-col"
    :style="stickyStyles.body"
  >
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
</template>
