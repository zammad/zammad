<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { whenever } from '@vueuse/shared'
import { unionBy } from 'lodash-es'
import { computed, nextTick } from 'vue'
import { useRoute } from 'vue-router'

import { edgesToArray, waitForAnimationFrame, waitForElement } from '#shared/utils/helpers.ts'

import ArticleBubble from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubble.vue'
import ArticleMore from '#desktop/pages/ticket/components/TicketDetailView/ArticleMore.vue'
import DeliveryMessage from '#desktop/pages/ticket/components/TicketDetailView/DeliveryMessage.vue'
import SystemMessage from '#desktop/pages/ticket/components/TicketDetailView/SystemMessage.vue'
import { useArticleContext } from '#desktop/pages/ticket/composables/useArticleContext.ts'
import { useTicketArticleRows } from '#desktop/pages/ticket/composables/useTicketArticlesRows.ts'

interface Props {
  isLoadingArticles: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  'scroll-to-end': []
}>()

const route = useRoute()
const { context } = useArticleContext()

const totalCount = computed(() => context.articles.value?.articles.totalCount || 0)

const leadingNodesCount = computed(() => edgesToArray(context.articles.value?.firstArticles).length)

const articles = computed(() => {
  if (!context.articles.value) {
    return []
  }
  const leadingNodes = edgesToArray(context.articles.value.firstArticles)
  const trailingNodes = edgesToArray(context.articles.value.articles)

  return unionBy(leadingNodes, trailingNodes, (elem) => elem.id)
})

const { rows } = useTicketArticleRows(articles, leadingNodesCount, totalCount)

const loadPrevious = async () => {
  await context.articlesQuery.fetchMore({
    variables: {
      pageSize: 100,
      loadFirstArticles: false,
      beforeCursor: context.articles.value?.articles.pageInfo.startCursor,
    },
  })
}

const isLoading = computed(() => context.articlesQuery.loadingWithoutCachedResult().value)

const getArticleElement = async (key: string): Promise<Element | null> => {
  const row = rows.value.find(
    (elem) => 'article' in elem && elem.article.internalId === parseInt(key, 10),
  )

  if (!row) return Promise.resolve(null)

  return waitForElement(`#article-${row.key}`)
}

const hasMoreButton = computed(() => {
  return !!rows.value.find((elem) => elem.type === 'more')
})

const getPreviousArticleElement = async (key: string): Promise<Element | null> => {
  const elem = await getArticleElement(key)

  if (elem || !hasMoreButton.value) return elem

  await loadPrevious()
  return getPreviousArticleElement(key)
}

const scrollToArticle = async () => {
  let targetElement

  if (route.hash) {
    const articleInternalId = route.hash?.replace('#article-', '')

    targetElement = await getPreviousArticleElement(articleInternalId)
  }

  if (!targetElement) {
    const targetRow = rows.value[rows.value.length - 1]

    targetElement = await waitForElement(`#article-${targetRow?.key}`)

    return emit('scroll-to-end')
  }

  const listScrollContainer = targetElement.closest('[class*="overflow-y-auto"]') as HTMLElement

  if (listScrollContainer) {
    const containerRect = listScrollContainer.getBoundingClientRect()
    const elementRect = targetElement.getBoundingClientRect()
    const relativeTop = elementRect.top - containerRect.top
    const scrollTop = listScrollContainer.scrollTop + relativeTop

    return listScrollContainer.scrollTo({
      top: Math.max(0, scrollTop),
      behavior: 'instant',
    })
  }

  targetElement?.scrollIntoView({ behavior: 'instant', block: 'start' })
}

// Afterwards the useScrollPosition hook takes care of the position
whenever(
  () => rows.value.length > 0,
  () => {
    nextTick(() => {
      waitForAnimationFrame().then(() => scrollToArticle())
    })
  },
  { once: true, immediate: true },
)
</script>

<template>
  <section
    role="feed"
    :aria-busy="isLoadingArticles"
    class="mx-auto w-full max-w-6xl space-y-10 px-12 pt-4 pb-8"
  >
    <template v-if="context.articles.value?.articles.edges && rows">
      <article
        v-for="(row, rowIndex) in rows"
        :id="`article-${row.key}`"
        :key="row.key"
        :aria-setsize="totalCount"
        :aria-posinset="rowIndex + 1"
      >
        <ArticleBubble v-if="row.type === 'article-bubble'" :article="row.article" />
        <ArticleMore
          v-else-if="row.type === 'more'"
          :disabled="isLoading"
          @click="loadPrevious()"
        />
        <DeliveryMessage
          v-else-if="row.type === 'delivery' && row.content"
          role="article"
          :content="row.content"
        />
        <SystemMessage
          v-else-if="row.type === 'system' && row.subject"
          role="article"
          :subject="row.subject"
          :to="row.to"
          :reaction="row.reaction"
        />
      </article>
    </template>
  </section>
</template>
