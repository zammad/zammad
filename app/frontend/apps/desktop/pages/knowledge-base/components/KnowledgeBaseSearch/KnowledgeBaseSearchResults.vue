<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useInfiniteScroll } from '@vueuse/core'
import { computed, toRef } from 'vue'

import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { EnumKnowledgeBaseSearchEntity } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

import { useKnowledgeBaseSearch } from '../../composables/useKnowledgeBaseSearch.ts'
import { CATEGORY_GRID_CLASSES } from '../../utils/knowledgeBaseCategoryGrid.ts'
import KnowledgeBaseContentTabs from '../KnowledgeBaseContentTabs/KnowledgeBaseContentTabs.vue'

import KnowledgeBaseSearchResultItem from './KnowledgeBaseSearchResultItem.vue'
import KnowledgeBaseSearchResultsSkeleton from './KnowledgeBaseSearchResultsSkeleton.vue'

import type { KnowledgeBaseContentScope } from '../../types.ts'

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

// Which kind of content is listed. Owned by the URL (useKnowledgeBaseSearchTerm), so a reload, a
//   shared link and a back/forward all restore the tab that was open.
const entity = defineModel<EnumKnowledgeBaseSearchEntity>('entity', { required: true })

const emit = defineEmits<{
  'clear-search': []
}>()

const { results, totalCount, answerCount, categoryCount, pagination, loading, debouncedLoading } =
  useKnowledgeBaseSearch({
    query: toRef(props, 'query'),
    entity,
    categoryId: toRef(props, 'categoryId'),
    locale: toRef(props, 'locale'),
  })

// The tabs are keyed by the content scope the browse page uses for its own listings, while the
//   query and the URL speak the schema's enum. A map each way keeps the two spellings apart
//   without a second vocabulary for either.
const TAB_BY_ENTITY: Record<EnumKnowledgeBaseSearchEntity, KnowledgeBaseContentScope> = {
  [EnumKnowledgeBaseSearchEntity.Answer]: 'answers',
  [EnumKnowledgeBaseSearchEntity.Category]: 'categories',
}

const ENTITY_BY_TAB: Record<KnowledgeBaseContentScope, EnumKnowledgeBaseSearchEntity> = {
  answers: EnumKnowledgeBaseSearchEntity.Answer,
  categories: EnumKnowledgeBaseSearchEntity.Category,
}

const activeTab = computed<KnowledgeBaseContentScope>({
  get: () => TAB_BY_ENTITY[entity.value],
  set: (tab) => {
    entity.value = ENTITY_BY_TAB[tab]
  },
})

// The categories are shown as the card grid the browse view lists them in, the answers as the
//   list they already were. The result item picks the matching shape for itself.
const listClasses = computed(() =>
  activeTab.value === 'categories' ? CATEGORY_GRID_CLASSES : 'flex flex-col gap-4',
)

useInfiniteScroll(
  () => props.contentContainerElement,
  () => pagination.value.fetchNextPage(),
  {
    distance: 100,
    canLoadMore: () => pagination.value.hasNextPage,
  },
)

const { debouncedLoading: loadingNewPage } = useDebouncedLoading({
  isLoading: computed(() => pagination.value.loadingNewPage ?? false),
})

// Judged by the total of the listed kind, not the loaded page, and only once the answer is in —
//   before that the count is still the empty default. The other tab keeps showing its own count,
//   which is what tells the user there are hits of the other kind.
const noResults = computed(() => !loading.value && totalCount.value === 0)
</script>

<template>
  <div class="flex grow flex-col gap-4">
    <!-- Outside the loader: switching the kind is the same search, so the tabs have to stay put
         and their counts must not flicker through a skeleton. -->
    <KnowledgeBaseContentTabs
      v-model="activeTab"
      reverse-order
      :answer-count="answerCount ?? '-'"
      :category-count="categoryCount ?? '-'"
    />

    <!-- The panel the tabs above point at through their `aria-controls`. Around the loader
         rather than on it: CommonLoader sets `inheritAttrs: false` and binds `$attrs` only on
         its loading and error branches, so the loaded results would carry neither the id nor
         the role - and the reference has to hold in every state. -->
    <div
      :id="`tab-panel-${activeTab}`"
      role="tabpanel"
      :aria-labelledby="`tab-label-${activeTab}`"
      class="flex grow flex-col"
    >
      <CommonLoader class="flex grow flex-col" :loading="debouncedLoading">
        <template #skeleton>
          <KnowledgeBaseSearchResultsSkeleton :scope="activeTab" />
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
            <ol :class="listClasses">
              <KnowledgeBaseSearchResultItem
                v-for="result in results"
                :key="result.item.id"
                :result="result"
                :query="query"
                :category-id="categoryId"
              />
            </ol>
            <KnowledgeBaseSearchResultsSkeleton
              v-if="loadingNewPage"
              :scope="activeTab"
              class="mt-4"
            />
          </template>
        </div>
      </CommonLoader>
    </div>
  </div>
</template>
