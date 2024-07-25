<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { unionBy } from 'lodash-es'
import { computed, watch, ref, nextTick } from 'vue'
import { useRouter } from 'vue-router'

import { edgesToArray, waitForElement } from '#shared/utils/helpers.ts'

import ArticleBubble from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubble.vue'
import ArticleMore from '#desktop/pages/ticket/components/TicketDetailView/ArticleMore.vue'
import DeliveryMessage from '#desktop/pages/ticket/components/TicketDetailView/DeliveryMessage.vue'
import SystemMessage from '#desktop/pages/ticket/components/TicketDetailView/SystemMessage.vue'
import { useArticleContext } from '#desktop/pages/ticket/composables/useArticleContext.ts'
import { useTicketArticleRows } from '#desktop/pages/ticket/composables/useTicketArticlesRows.ts'

import { useTicketInformation } from '../../composables/useTicketInformation.ts'

const router = useRouter()
const { context } = useArticleContext()

const totalCount = computed(
  () => context.articles.value?.articles.totalCount || 0,
)

const leadingNodesCount = computed(
  () => edgesToArray(context.articles.value?.firstArticles).length,
)

const { ticket } = useTicketInformation()

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

const isLoading = computed(() => context.articlesQuery.loading().value)

const getArticleOrderNumber = (index: number) =>
  Math.abs(totalCount.value - (rows.value.length - (index + 1)))

const getArticleElement = async (key: string): Promise<Element | null> => {
  const row = rows.value.find(
    (elem) =>
      'article' in elem && elem.article.internalId === parseInt(key, 10),
  )

  if (!row) return Promise.resolve(null)

  return waitForElement(`#article-list-row-${row.key}`)
}

const hasMoreButton = computed(() => {
  return !!rows.value.find((elem) => elem.type === 'more')
})

const getPreviousArticleElement = async (
  key: string,
): Promise<Element | null> => {
  const elem = await getArticleElement(key)

  if (elem || !hasMoreButton.value) return elem

  await loadPrevious()
  return getPreviousArticleElement(key)
}

const initialScroll = async () => {
  let targetElement
  if (router.currentRoute.value.hash) {
    const articleInternalId = router.currentRoute.value.hash?.replace(
      '#article-',
      '',
    )

    targetElement = await getPreviousArticleElement(articleInternalId)
  }

  if (!targetElement) {
    const targetRow = rows.value[rows.value.length - 1]
    targetElement = await waitForElement(`#article-list-row-${targetRow.key}`)
  }

  if (!targetElement) return false

  targetElement?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

const didScrollInitially = ref(false)

watch(
  () => ticket.value?.id,
  () => {
    didScrollInitially.value = false
  },
  { immediate: true },
)

watch(
  rows,
  async () => {
    if (didScrollInitially.value) return
    didScrollInitially.value = true
    await nextTick()
    initialScroll()
  },
  { immediate: true },
)
</script>

<template>
  <section class="mx-auto w-full max-w-6xl px-12 py-4">
    <TransitionGroup
      v-if="context.articles.value?.articles.edges"
      tag="div"
      name="list"
      class="space-y-10"
      enter-from-class="opacity-0"
      enter-active-class="duration-500"
    >
      <template v-for="(row, rowIndex) in rows" :key="row.key">
        <div :id="`article-list-row-${row.key}`" class="scroll-mt-[12rem]">
          <ArticleBubble
            v-if="row.type === 'article-bubble'"
            :aria-setsize="totalCount"
            :aria-posinset="getArticleOrderNumber(rowIndex)"
            :article="row.article"
          />
          <ArticleMore
            v-else-if="row.type === 'more'"
            :disabled="isLoading"
            @click="loadPrevious()"
          />
          <DeliveryMessage
            v-else-if="row.type === 'delivery' && row.content"
            role="article"
            :aria-setsize="totalCount"
            :aria-posinset="getArticleOrderNumber(rowIndex)"
            :content="row.content"
          />
          <SystemMessage
            v-else-if="row.type === 'system' && row.subject"
            role="article"
            :aria-setsize="totalCount"
            :aria-posinset="getArticleOrderNumber(rowIndex)"
            :subject="row.subject"
            :to="row.to"
          />
        </div>
      </template>
    </TransitionGroup>
  </section>
</template>
