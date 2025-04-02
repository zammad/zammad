<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual, omit } from 'lodash-es'
import { computed, ref, useTemplateRef, watch, type Ref, nextTick } from 'vue'
import { useRouter } from 'vue-router'

import { useSorting } from '#shared/composables/list/useSorting.ts'
import {
  type DetailSearchQuery,
  type DetailSearchQueryVariables,
  type EnumOrderDirection,
  EnumSearchableModels,
  type SearchCountsQuery,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useSkeletonLoadingCount } from '#desktop/components/CommonTable/composables/useSkeletonLoadingCount.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useDetailSearchLazyQuery } from '#desktop/components/Search/graphql/queries/detailSearch.api.ts'
import { useSearchCountsLazyQuery } from '#desktop/components/Search/graphql/queries/searchCounts.api.ts'
import {
  searchPluginByName,
  useSearchPlugins,
} from '#desktop/components/Search/plugins/index.ts'
import TicketBulkEditButton from '#desktop/components/Ticket/TicketBulkEditButton.vue'
import { useTicketBulkEdit } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { usePage } from '#desktop/composables/usePage.ts'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import type { TaskbarTabContext } from '#desktop/entities/user/current/types.ts'
import SearchControls from '#desktop/pages/search/components/SearchControls.vue'
import SearchEmptyMessage from '#desktop/pages/search/components/SearchEmptyMessage.vue'
import { useDetailSearchCache } from '#desktop/pages/search/composables/useDetailSearchCache.ts'

const MAX_ITEMS = 1000
const PAGE_SIZE = 30

const props = defineProps<{
  searchTerm?: string
}>()

const router = useRouter()

const selectedEntity = ref(
  (router.currentRoute.value.query.entity as EnumSearchableModels) ??
    EnumSearchableModels.Ticket,
)

watch(selectedEntity, (newValue) => {
  router.replace({
    query: {
      entity: newValue,
    },
  })
})

const modelSearchTerm = computed({
  get: () => props.searchTerm,
  set: (searchTerm) => {
    router.push({
      params: {
        searchTerm,
      },
      query: {
        entity: selectedEntity.value,
      },
    })
  },
})

const sanitizedSearchTerm = computed(() => modelSearchTerm.value ?? '')

const tabContext = computed<TaskbarTabContext>((currentContext) => {
  const newContext = {
    query: sanitizedSearchTerm.value,
    model: selectedEntity.value,
  }

  if (currentContext && isEqual(newContext, currentContext))
    return currentContext

  return newContext
})

const { currentTaskbarTab, currentTaskbarTabUpdate } = useTaskbarTab(tabContext)

watch(tabContext, (newValue) => {
  if (!currentTaskbarTab.value) return

  if (isEqual(newValue, omit(currentTaskbarTab.value.entity, '__typename')))
    return

  currentTaskbarTabUpdate(currentTaskbarTab.value, newValue)
})

const scrollContainerElement = useTemplateRef('scroll-container')

const { reachedTop } = useElementScroll(
  scrollContainerElement as Ref<HTMLElement>,
)

const searchControlsInstance = useTemplateRef('search-controls')

const { sortedByNamePlugins, searchPluginNames } = useSearchPlugins()

const searchQueryVariables = computed(() => ({
  search: sanitizedSearchTerm.value,
  limit: PAGE_SIZE,
  onlyIn: selectedEntity.value,
}))

const detailSearchQuery = new QueryHandler(
  useDetailSearchLazyQuery(searchQueryVariables, {
    context: {
      batch: {
        active: false,
      },
    },
    fetchPolicy: 'cache-and-network', // TODO: for now until the cache handling is implemented
  }),
)

const notVisibleSearchEntities = computed(() =>
  searchPluginNames.value.filter((name) => name !== selectedEntity.value),
)

// Remember this in a static way to avoid unnecessary re-fetchtings of the search counts.
let staticNotVisibleSearchEntities = notVisibleSearchEntities.value

watch(notVisibleSearchEntities, (newValue) => {
  staticNotVisibleSearchEntities = newValue
})

const searchCountsQuery = new QueryHandler(
  useSearchCountsLazyQuery(
    () => {
      return {
        search: sanitizedSearchTerm.value,
        onlyIn: staticNotVisibleSearchEntities,
      }
    },
    () => ({
      context: {
        batch: {
          active: false,
        },
      },
      fetchPolicy: 'cache-and-network', // TODO: for now until the cache handling is implemented
      enabled: searchPluginNames.value.length > 1,
    }),
  ),
)

const searchQueriesLoad = () => {
  detailSearchQuery.load()
  searchCountsQuery.load()
}

const searchQueriesStart = () => {
  detailSearchQuery.start()
  searchCountsQuery.start()
}

const searchEntityCurrentCounts = ref<
  Partial<Record<EnumSearchableModels, number>>
>({})

const searchPlugin = computed(() => searchPluginByName[selectedEntity.value])

const searchResult = detailSearchQuery.result()
const currentSearchResult = ref<DetailSearchQuery>()
const loading = detailSearchQuery.loading()

// Remember the current search result to avoid always showing the loading state on search term changes.
// Because the apollo cache is returning undefined when nothing is in currently in the cache.
watch(searchResult, (newValue) => {
  if (!newValue) return

  currentSearchResult.value = newValue
})

const searchCountsResult = searchCountsQuery.result()
const currentSearchCountsResult = ref<SearchCountsQuery>()

// Remember the current search counts result to avoid always showing the loading state on search term changes.
// Because the apollo cache is returning undefined when nothing is in currently in the cache.
watch(searchCountsResult, (newValue) => {
  if (!newValue) return

  currentSearchCountsResult.value = newValue
})

const searchQueriesStop = () => {
  currentSearchResult.value = undefined
  searchEntityCurrentCounts.value = {}
  currentSearchCountsResult.value = undefined

  detailSearchQuery.stop()
  searchCountsQuery.stop()
}

const currentSearchCounts = computed(() =>
  currentSearchCountsResult.value?.searchCounts.reduce(
    (acc, curr) => {
      acc[curr.model] = curr.totalCount
      return acc
    },
    {} as Record<EnumSearchableModels, number>,
  ),
)

const isLoading = computed(() => {
  if (currentSearchResult.value !== undefined) return false

  return loading.value
})

const searchResultTotalCount = computed(
  () => currentSearchResult.value?.search.totalCount ?? 0,
)
const searchResultItems = computed(
  () => currentSearchResult.value?.search.items || [],
)

// Update counts when needed, but hold the counts always in one object.
watch([currentSearchCounts, searchResultTotalCount], () => {
  searchEntityCurrentCounts.value = Object.assign(
    searchEntityCurrentCounts.value,
    currentSearchCounts.value,
  )

  // Change only the current entity count, when needed.
  if (
    currentSearchResult.value !== undefined &&
    searchEntityCurrentCounts.value[selectedEntity.value] !==
      currentSearchResult.value.search.totalCount
  ) {
    searchEntityCurrentCounts.value[selectedEntity.value] =
      currentSearchResult.value.search.totalCount
  }
})

const searchTabs = computed(() =>
  sortedByNamePlugins.value.map((plugin) => {
    return {
      label: plugin.label,
      key: plugin.name,
      count: searchEntityCurrentCounts.value[plugin.name] ?? 0,
    }
  }),
)

const { forceDetailSearchCacheOnlyFirstPage } = useDetailSearchCache()

const { sort, orderBy, orderDirection, isSorting } = useSorting(
  detailSearchQuery,
  undefined,
  undefined,
  scrollContainerElement,
)

const offset = ref(0)
const loadingNewPage = ref(false)

const resetPagination = (
  variables: Partial<DetailSearchQueryVariables> = {},
) => {
  offset.value = 0

  forceDetailSearchCacheOnlyFirstPage(
    {
      ...searchQueryVariables.value,
      ...variables,
      orderBy: orderBy.value,
      orderDirection: orderDirection.value,
    },
    PAGE_SIZE,
  )
}

const resort = (column: string, direction: EnumOrderDirection) => {
  resetPagination()

  sort(column, direction)
}

const fetchNextPage = async () => {
  offset.value += PAGE_SIZE

  loadingNewPage.value = true

  try {
    await detailSearchQuery.fetchMore({
      variables: {
        limit: PAGE_SIZE,
        offset: offset.value,
      },
    })
  } finally {
    loadingNewPage.value = false
  }
}

const refetchQueries = () => {
  detailSearchQuery.refetch({
    limit: offset.value + PAGE_SIZE,
  })
  searchCountsQuery.refetch()
}

const { checkedTicketIds, openBulkEditFlyout, setOnSuccessCallback } =
  useTicketBulkEdit()

watch(
  sanitizedSearchTerm,
  (newValue, oldValue) => {
    if (newValue !== oldValue) checkedTicketIds.value.clear()

    if (newValue && detailSearchQuery.isFirstRun()) {
      searchQueriesLoad()
      return
    }

    resetPagination({
      search: oldValue,
    })

    if (oldValue && !newValue) searchQueriesStop()
    else if (newValue && !oldValue) nextTick(searchQueriesStart)
  },
  { immediate: true },
)

watch(selectedEntity, (_, oldValue) => {
  currentSearchResult.value = undefined

  checkedTicketIds.value.clear()

  resetPagination({
    onlyIn: oldValue,
  })
})

const currentSearchResultCount = computed(
  () => searchEntityCurrentCounts.value[selectedEntity.value],
)

const { visibleSkeletonLoadingCount } = useSkeletonLoadingCount(
  currentSearchResultCount,
)

const breadcrumbItems = computed(() => [
  { label: __('Search') },
  {
    label: __('Results'),
    isActive: true,
    count: currentSearchResultCount.value,
  },
])

const { pageInactive } = usePage({
  metaTitle: sanitizedSearchTerm,
  onReactivate: () => refetchQueries(),
})

watch(
  () => router.currentRoute.value.query.entity,
  (newValue) => {
    nextTick(() => {
      if (pageInactive.value) return

      selectedEntity.value = newValue as EnumSearchableModels
    })
  },
)

setOnSuccessCallback(() => {
  resetPagination()
  refetchQueries()
  requestAnimationFrame(() => {
    scrollContainerElement.value?.scrollTo({ top: 0 })
  })
})
</script>

<template>
  <LayoutContent
    content-padding
    no-scrollable
    :breadcrumb-items="breadcrumbItems"
  >
    <template #headerRight>
      <TicketBulkEditButton
        v-if="selectedEntity === EnumSearchableModels.Ticket"
        :checked-ticket-ids="checkedTicketIds"
        @open-flyout="openBulkEditFlyout"
      />
    </template>
    <div
      class="flex h-full flex-col overflow-hidden"
      data-test-id="search-container"
    >
      <SearchControls
        ref="search-controls"
        v-model:search="modelSearchTerm"
        v-model:selected-entity="selectedEntity"
        :search-tabs="searchTabs"
        class="px-4"
      />
      <div
        :id="`tab-panel-${selectedEntity}`"
        ref="scroll-container"
        :data-test-id="`tab-panel-${selectedEntity}`"
        class="relative grow overflow-y-auto px-4 pb-4"
      >
        <component
          :is="searchPlugin.detailSearchComponent"
          :key="selectedEntity"
          :table-id="`search-${selectedEntity}-table`"
          :caption="`Search result for: ${searchPlugin.label}`"
          :items="searchResultItems"
          :headers="searchPlugin.detailSearchHeaders"
          :total-count="searchResultTotalCount"
          :order-by="orderBy"
          :order-direction="orderDirection"
          :loading="isLoading"
          :resorting="isSorting"
          :max-items="MAX_ITEMS"
          :loading-new-page="loadingNewPage"
          :reached-scroll-top="reachedTop"
          :scroll-container="scrollContainerElement"
          :skeleton-loading-count="visibleSkeletonLoadingCount"
          @load-more="fetchNextPage"
          @sort="resort"
        >
          <template #empty-list>
            <SearchEmptyMessage
              class="absolute top-1/2 -translate-y-1/2 ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
              :search-term="sanitizedSearchTerm"
              :results="searchResultItems"
              @clear-search-input="
                () => searchControlsInstance?.clearAndFocusSearch()
              "
            />
          </template>
        </component>
      </div>
    </div>
  </LayoutContent>
</template>
