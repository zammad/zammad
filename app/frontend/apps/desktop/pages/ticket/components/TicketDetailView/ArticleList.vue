<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { whenever } from '@vueuse/shared'
import { unionBy } from 'lodash-es'
import { computed, nextTick, useTemplateRef } from 'vue'
import { useRoute } from 'vue-router'

import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'
import { edgesToArray, waitForAnimationFrame, waitForElement } from '#shared/utils/helpers.ts'

import ArticleBubble from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubble.vue'
import ArticleMore from '#desktop/pages/ticket/components/TicketDetailView/ArticleMore.vue'
import DeliveryMessage from '#desktop/pages/ticket/components/TicketDetailView/DeliveryMessage.vue'
import SystemMessage from '#desktop/pages/ticket/components/TicketDetailView/SystemMessage.vue'
import { useArticleContext } from '#desktop/pages/ticket/composables/useArticleContext.ts'
import { useTicketArticleRows } from '#desktop/pages/ticket/composables/useTicketArticlesRows.ts'

import { useActiveArticle } from './useActiveArticle.ts'

interface Props {
  isLoadingArticles: boolean
  scrollContainer?: HTMLElement | null
  unreadArticleIds?: Set<string>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'scroll-to-end': [isPermalink: boolean]
}>()

const PAGE_SIZE = 100

const route = useRoute()
const { context } = useArticleContext()

const leadingNodes = computed(() => edgesToArray(context.articles.value?.firstArticles))
const leadingNodesCount = computed(() => leadingNodes.value.length)

const articles = computed(() => {
  if (!context.articles.value) return []

  const trailingNodes = edgesToArray(context.articles.value.articles)

  return unionBy(leadingNodes.value, trailingNodes, (elem) => elem.id)
})

const totalCount = computed(() => context.articles.value?.articles.totalCount || 0)

const nextFetchCount = computed(() => {
  const loadedArticlesCount = articles.value.length
  const totalArticles = totalCount.value

  const remainingCount = Math.max(0, totalArticles - loadedArticlesCount)

  return remainingCount > PAGE_SIZE ? PAGE_SIZE : remainingCount
})

const { rows } = useTicketArticleRows(articles, leadingNodesCount, totalCount)

const articleElements = useTemplateRef<HTMLElement[]>('article-elements')

const { topHeaderHeight } = useActiveArticle(rows, articleElements, () => props.scrollContainer)

const loadPrevious = async () => {
  await context.articlesQuery.fetchMore({
    variables: {
      pageSize: PAGE_SIZE,
      loadFirstArticles: false,
      beforeCursor: context.articles.value?.articles.pageInfo.startCursor,
    },
  })
}

const isFetchingMore = context.articlesQuery.loading()

const getArticleElement = async (key: string): Promise<Element | null> => {
  const row = rows.value.find(
    (elem) => 'article' in elem && elem.article.internalId === parseInt(key, 10),
  )

  if (!row) return Promise.resolve(null)

  return waitForElement(`#article-${row.key}`)
}

const hasMoreButton = computed(() => rows.value.some((elem) => elem.type === 'more'))

const getPreviousArticleElement = async (key: string): Promise<Element | null> => {
  const elem = await getArticleElement(key)

  if (elem || !hasMoreButton.value) return elem

  await loadPrevious()
  return getPreviousArticleElement(key)
}

const ARTICLE_GAP = 40

const scrollElementToContainerTop = (
  targetElement: Element,
  behavior: ScrollBehavior = 'instant',
) => {
  const listScrollContainer =
    props.scrollContainer ??
    (targetElement.closest('[class*="overflow-y-auto"]') as HTMLElement | null)

  if (listScrollContainer) {
    const headerOffset = Math.max(0, parseInt(topHeaderHeight.value || '0', 10)) + ARTICLE_GAP
    const containerRect = listScrollContainer.getBoundingClientRect()
    const elementRect = targetElement.getBoundingClientRect()
    const relativeTop = elementRect.top - containerRect.top - headerOffset
    const scrollTop = listScrollContainer.scrollTop + relativeTop

    listScrollContainer.scrollTo({
      top: Math.max(0, scrollTop),
      behavior,
    })

    return
  }

  targetElement.scrollIntoView({ behavior, block: 'start' })
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

    emit('scroll-to-end', false)
    return
  }

  scrollElementToContainerTop(targetElement)
  emit('scroll-to-end', true)
}

const { scrollBehavior } = useReducedMotion()

// Navigate between article-bubbles relative to the visible content edge
// (container top + sticky header height). DOM positions are read live at call
// time so stale cached values are never used.
// "next"     → first article whose top starts below the reference edge.
// "previous" → last article whose top starts above it (a partially scrolled
//   article first snaps its own top back into view before stepping further up).
// Returns false when there is no candidate, letting the caller scroll all the
// way to the very top/bottom.
const goToAdjacentArticle = (direction: 'next' | 'previous' | 'unread') => {
  const container = props.scrollContainer

  if (!container || !rows.value.length) return false

  const headerOffset = Math.max(0, parseInt(topHeaderHeight.value || '0', 10)) + ARTICLE_GAP
  const referenceTop = container.getBoundingClientRect().top + headerOffset

  // Tolerance so an article already resting exactly at the reference edge is
  // not picked as its own previous/next target (sub-pixel offsets after snapping).
  const EPSILON = 2

  const candidates = rows.value.flatMap((row) => {
    const el = articleElements.value?.find((e) => e.id === `article-${row.key}`)

    return el ? [{ el, top: el.getBoundingClientRect().top, row }] : []
  })

  const findTarget = {
    unread: () =>
      candidates.find(({ row }) => 'article' in row && props.unreadArticleIds?.has(row.article.id)),
    next: () => candidates.find(({ top }) => top - referenceTop > EPSILON),
    previous: () => candidates.findLast(({ top }) => top - referenceTop < -EPSILON),
  }

  const target = findTarget[direction]()

  if (!target) return false

  scrollElementToContainerTop(target.el, scrollBehavior.value)

  return true
}

// Afterwards the useScrollPosition hook takes care of the position
whenever(
  () => rows.value.length > 0,
  async () => {
    await Promise.allSettled([nextTick(), waitForAnimationFrame()])
    await scrollToArticle()
  },
  { once: true, immediate: true },
)

defineExpose({ goToAdjacentArticle })
</script>

<template>
  <section
    role="feed"
    :aria-busy="isLoadingArticles"
    class="mx-auto w-full max-w-4xl min-w-xs space-y-10 px-16 py-3 pb-8 print:pt-0!"
  >
    <template v-if="context.articles.value?.articles.edges && rows">
      <article
        v-for="(row, rowIndex) in rows"
        :id="`article-${row.key}`"
        ref="article-elements"
        :key="row.key"
        :aria-setsize="totalCount"
        :aria-posinset="rowIndex + 1"
      >
        <ArticleBubble v-if="row.type === 'article-bubble'" :article="row.article" />
        <ArticleMore
          v-else-if="row.type === 'more'"
          :disabled="isFetchingMore"
          :next-fetch-count="nextFetchCount"
          @load-more="loadPrevious()"
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
