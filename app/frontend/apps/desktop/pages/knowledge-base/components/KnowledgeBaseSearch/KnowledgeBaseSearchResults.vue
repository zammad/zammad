<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useInfiniteScroll } from '@vueuse/core'
import { computed, toRef } from 'vue'

import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

import { useKnowledgeBaseSearch } from '../../composables/useKnowledgeBaseSearch.ts'

import KnowledgeBaseSearchResultItem from './KnowledgeBaseSearchResultItem.vue'
import KnowledgeBaseSearchResultsSkeleton from './KnowledgeBaseSearchResultsSkeleton.vue'

const props = defineProps<{
  // The searched term as committed to the URL, so already debounced.
  query: string
  // The browsed category; without one (the knowledge base root) the whole base is searched.
  categoryId?: string
  // The browsed locale, forwarded from the page (the URL route prop).
  locale?: string
  // The layout's scroll container; it drives the infinite scroll.
  contentContainerElement?: HTMLElement | null
}>()

const emit = defineEmits<{
  'clear-search': []
}>()

const { results, totalCount, pagination, loading, debouncedLoading } = useKnowledgeBaseSearch({
  query: toRef(props, 'query'),
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

const { debouncedLoading: loadingNewPage } = useDebouncedLoading({
  isLoading: computed(() => pagination.loadingNewPage ?? false),
})

// Judged by the total, not the loaded page, and only once the answer is in — before that the
//   count is still the empty default.
const noResults = computed(() => !loading.value && totalCount.value === 0)
</script>

<template>
  <CommonLoader class="flex grow flex-col" :loading="debouncedLoading">
    <template #skeleton>
      <KnowledgeBaseSearchResultsSkeleton />
    </template>

    <!-- One root element: the loader renders its slot inside a <Transition>. -->
    <div class="flex grow flex-col">
      <div
        v-if="noResults"
        class="flex grow flex-col items-center justify-center gap-4 py-8"
        role="status"
      >
        <CommonIcon decorative name="search" size="medium" class="dark:text-neutral-500" />
        <CommonLabel tag="p" class="dark:text-neutral-500">
          {{ $t('No search results for this query.') }}
        </CommonLabel>
        <CommonButton variant="secondary" size="medium" @click="emit('clear-search')">
          {{ $t('Clear search') }}
        </CommonButton>
      </div>

      <template v-else>
        <ol class="flex flex-col gap-4">
          <KnowledgeBaseSearchResultItem
            v-for="result in results"
            :key="result.item.id"
            :result="result"
            :query="query"
            :category-id="categoryId"
          />
        </ol>
        <KnowledgeBaseSearchResultsSkeleton v-if="loadingNewPage" class="mt-4" />
      </template>
    </div>
  </CommonLoader>
</template>
