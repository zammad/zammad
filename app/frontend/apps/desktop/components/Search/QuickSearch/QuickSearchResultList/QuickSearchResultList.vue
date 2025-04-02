<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { refDebounced } from '@vueuse/core'
import { whenever } from '@vueuse/shared'
import { computed, toRef } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import { useQuickSearchLazyQuery } from '#desktop/components/Search/graphql/queries/quickSearch.api.ts'
import type { QuickSearchResultData } from '#desktop/components/Search/types.ts'

import { useSearchPlugins } from '../../plugins/index.ts'
import { useQuickSearchInput } from '../useQuickSearchInput.ts'

const RESULT_LIMIT = 10

interface Props {
  search: string
  debounceTime: number
}

const props = defineProps<Props>()

const { sortedByPriorityPlugins } = useSearchPlugins()

const userSearchInput = toRef(props, 'search')

const debouncedSearch = refDebounced<string>(
  userSearchInput,
  props.debounceTime,
)

const quickSearchQuery = new QueryHandler(
  useQuickSearchLazyQuery(
    () => ({
      search: debouncedSearch.value,
      limit: RESULT_LIMIT,
    }),
    {
      fetchPolicy: 'no-cache',
      context: {
        batch: {
          active: false,
        },
      },
    },
  ),
)

const quickSearchResult = quickSearchQuery.result()
const searchResultsLoading = quickSearchQuery.loading()

whenever(
  debouncedSearch,
  () => {
    quickSearchQuery.load()
  },
  { once: true, immediate: true },
)

const mappedQuickSearchResults = computed(() => {
  const currentResult = quickSearchResult.value

  if (!currentResult) return

  const searchResults: QuickSearchResultData[] = []

  sortedByPriorityPlugins.value.forEach((plugin) => {
    if (!currentResult[plugin.quickSearchResultKey]) return

    const searchResult = currentResult[plugin.quickSearchResultKey]
    if (!searchResult || searchResult.totalCount === 0) return

    searchResults.push({
      name: plugin.name,
      component: plugin.quickSearchComponent,
      items: searchResult.items,
      label: plugin.quickSearchResultLabel,
      remainingItemCount: searchResult.totalCount - searchResult.items.length,
      totalCount: searchResult.totalCount,
    })
  })

  return searchResults
})

const isLoadingSearchResults = computed(() => {
  if (mappedQuickSearchResults.value !== undefined) return false

  return searchResultsLoading.value
})

const { debouncedLoading } = useDebouncedLoading({
  isLoading: isLoadingSearchResults,
  ms: 150,
})

const hasResults = computed(() =>
  Boolean(mappedQuickSearchResults.value?.length),
)

const { resetQuickSearchInputField } = useQuickSearchInput()
</script>

<template>
  <div v-if="debouncedLoading" class="mt-4 flex flex-col gap-8">
    <div v-for="i in 2" :key="i" class="flex flex-col gap-4">
      <CommonSkeleton
        v-for="j in 3"
        :key="j"
        class="block rounded-lg"
        :class="{
          'h-5 w-25': j === 1,
          'h-6 w-full': j !== 1,
        }"
        :style="{ 'animation-delay': `${(i * 3 + j) * 0.1}s` }"
      />
    </div>
  </div>
  <template v-else>
    <!-- TODO: Exchange the link to the proper route when ready. -->
    <CommonLink
      v-if="!isLoadingSearchResults"
      class="group/link mb-4 block"
      :link="{ name: 'search', params: { searchTerm: search } }"
      @click="resetQuickSearchInputField"
      @keydown.enter="$event.target.click()"
    >
      <CommonLabel
        class="text-blue-800! group-hover/link:underline"
        prefix-icon="search-detail"
        size="small"
      >
        {{ $t('detailed search') }}
      </CommonLabel>
    </CommonLink>

    <div v-if="hasResults" class="space-y-1">
      <CommonSectionCollapse
        v-for="(searchResult, index) in mappedQuickSearchResults"
        :id="`${searchResult.name}-${index}`"
        :key="`${searchResult.name}-${index}`"
        no-collapse
        :title="$t(searchResult.label)"
      >
        <div class="flex flex-col">
          <ol class="space-y-1.5">
            <li v-for="item in searchResult.items" :key="item.id">
              <component
                :is="searchResult.component"
                :item="item"
                mode="quick-search-result"
                @click="resetQuickSearchInputField"
              />
            </li>
          </ol>

          <CommonLink
            v-if="searchResult.remainingItemCount > 0"
            class="group/link my-1.5 ms-auto"
            :link="{
              name: 'search',
              params: { searchTerm: search },
              query: { entity: searchResult.name },
            }"
            @click="resetQuickSearchInputField"
            @keydown.enter="$event.target.click()"
          >
            <CommonLabel
              class="text-blue-800! group-hover/link:underline"
              prefix-icon="search-detail"
              size="small"
            >
              {{ $t('%s more', searchResult.remainingItemCount) }}
            </CommonLabel>
          </CommonLink>
        </div>
      </CommonSectionCollapse>
    </div>
    <CommonLabel v-else-if="!isLoadingSearchResults">{{
      $t('No results for this query.')
    }}</CommonLabel>
  </template>
</template>
