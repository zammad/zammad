<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useInfiniteScroll } from '@vueuse/core'
import { computed, toRef } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

import { useKnowledgeBaseAnswers } from '../composables/useKnowledgeBaseAnswers.ts'

import AnswerCard from './AnswerCard.vue'
import AnswerListSkeleton from './AnswerListSkeleton.vue'
import AnswerSkeleton from './AnswerSkeleton.vue'

const props = defineProps<{
  // The open category; without one (the knowledge base root) there are no answers.
  categoryId?: string
  // The browsed locale, forwarded from the page (the URL route prop).
  locale?: string
  // The layout's scroll container (it also scrolls the category grid); it drives
  //   the infinite scroll.
  contentContainerElement?: HTMLElement | null
}>()

const { answers, pagination, loading, totalAnswerCount } = useKnowledgeBaseAnswers({
  categoryId: toRef(props, 'categoryId'),
  locale: toRef(props, 'locale'),
})

useInfiniteScroll(
  () => props.contentContainerElement,
  () => pagination.fetchNextPage(),
  {
    distance: 100,
    canLoadMore: () => pagination.hasNextPage,
  },
)

const { debouncedLoading } = useDebouncedLoading({
  isLoading: computed(() => pagination.loadingNewPage ?? false),
})
</script>

<template>
  <CommonLoader :loading="loading">
    <ol class="mt-4 flex flex-col gap-4">
      <AnswerCard v-for="answer in answers" :key="answer.id" v-bind="answer" />
      <!-- todo: show add answer button instead of div-->
      <div v-if="categoryId && !answers.length"></div>
      <template v-if="debouncedLoading">
        <AnswerSkeleton v-for="i in 3" :key="i" :index="i" />
      </template>
    </ol>

    <template #skeleton>
      <AnswerListSkeleton :count="totalAnswerCount" />
    </template>
  </CommonLoader>
</template>
