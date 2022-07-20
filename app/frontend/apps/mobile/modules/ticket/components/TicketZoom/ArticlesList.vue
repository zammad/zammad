<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
// TODO scroll to bottom when data is loaded
import { toRef, shallowRef } from 'vue'
import CommonSectionPopup from '@mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import ArticleBubble from './ArticleBubble.vue'
import ArticlesPullDown from './ArticlesPullDown.vue'
import ArticleBadgeNew from './ArticleBadgeNew.vue'
import ArticleBadgeMore from './ArticleBadgeMore.vue'
import { TicketArticle } from '../../types/tickets'
import ArticleBadgeDate from './ArticleBadgeDate.vue'
import { useTicketArticleRows } from '../../composable/useTicketArticlesRows'
import { useTicketArticleContext } from '../../composable/useTicketArticleContext'
import ArticleSystem from './ArticleSystem.vue'

interface Props {
  articles: TicketArticle[]
}

const props = defineProps<Props>()

const { contextOptions, articleContextShown, showArticleContext } =
  useTicketArticleContext()

const articlesElement = shallowRef<HTMLElement>()
const loaderElement = shallowRef<{
  stopLoader(): void
}>()

const loadMoreArticles = () => {
  // start loading instead
  setTimeout(() => {
    loaderElement.value?.stopLoader()
  }, 1000)
}

const { rows } = useTicketArticleRows(toRef(props, 'articles'))
</script>

<template>
  <section
    ref="articlesElement"
    role="group"
    aria-label="Articles"
    class="relative flex-1 space-y-4 px-4 pt-4"
  >
    <!-- TODO counter indicator, use role="timer" -->
    <!-- <button
      class="absolute -top-7 right-4 flex h-14 w-14 items-center justify-center rounded-full bg-yellow text-black"
    >
      <CommonIcon class="rotate-180" size="medium" name="long-arrow-down" />
    </button> -->
    <template v-for="row in rows" :key="row.key">
      <!-- TODO add id="article-internalId" -->
      <ArticleBubble
        v-if="row.type === 'article-bubble'"
        :content="row.article.body"
        :user="row.article.createdBy"
        :internal="row.article.internal"
        :position="
          row.article.sender?.name !== 'Customer' || row.article.internal
            ? 'left'
            : 'right'
        "
        @show-context="showArticleContext(row.article)"
      />
      <ArticleSystem
        v-if="row.type === 'system'"
        :to="row.to"
        :subject="row.subject"
      />
      <ArticleBadgeDate v-if="row.type === 'date'" :date="row.date" />
      <ArticleBadgeNew v-if="row.type === 'new'" />
      <ArticleBadgeMore v-if="row.type === 'more'" :count="row.count" />
    </template>
  </section>
  <CommonSectionPopup
    v-model:state="articleContextShown"
    :items="contextOptions"
  />
  <ArticlesPullDown
    ref="loaderElement"
    :articles-element="articlesElement"
    @load="loadMoreArticles"
  />
</template>
