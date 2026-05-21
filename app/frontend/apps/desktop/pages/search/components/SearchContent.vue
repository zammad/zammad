<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watchDebounced } from '@vueuse/core'
import { isEqual, omit } from 'lodash-es'
import { storeToRefs } from 'pinia'
import {
  computed,
  ref,
  useTemplateRef,
  watch,
  type Ref,
  nextTick,
  shallowRef,
  onActivated,
  onBeforeMount,
} from 'vue'
import { stringifyQuery, useRoute, useRouter } from 'vue-router'

import { useSorting } from '#shared/composables/list/useSorting.ts'
import {
  type DetailSearchQueryVariables,
  type EnumOrderDirection,
  EnumSearchableModels,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { useSkeletonLoadingCount } from '#desktop/components/CommonTable/composables/useSkeletonLoadingCount.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useSearchTitle } from '#desktop/components/Search/composables/useSearchTitle.ts'
import { useDetailSearchLazyQuery } from '#desktop/components/Search/graphql/queries/detailSearch.api.ts'
import { useSearchCountsLazyQuery } from '#desktop/components/Search/graphql/queries/searchCounts.api.ts'
import { searchPluginByName, useSearchPlugins } from '#desktop/components/Search/plugins/index.ts'
import DragAndDropBulkWrapper from '#desktop/components/Ticket/DragAndDropBulk/DragAndDropBulkWrapper.vue'
import { useDragAndDropBulk } from '#desktop/components/Ticket/DragAndDropBulk/useDragAndDropBulk.ts'
import TicketBulkEditButton from '#desktop/components/Ticket/TicketBulkEditButton.vue'
import { useTicketBulkEdit } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { usePage } from '#desktop/composables/usePage.ts'
import { useTaskbarTab } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import type { TaskbarTabContext } from '#desktop/entities/user/current/types.ts'
import SearchControls from '#desktop/pages/search/components/SearchControls.vue'
import SearchEmptyMessage from '#desktop/pages/search/components/SearchEmptyMessage.vue'
import { useDetailSearchCache } from '#desktop/pages/search/composables/useDetailSearchCache.ts'
import { useSearchAdvancedFilters } from '#desktop/pages/search/composables/useSearchAdvancedFilters.ts'
import {
  buildSearchDeepLink,
  buildSearchRouteQuery,
} from '#desktop/pages/search/utils/searchRouteLink.ts'

import { decodeFilters, getSearchQueryWithoutFilters } from '../utils/searchFilterQuery.ts'

const MAX_ITEMS = 2000
const PAGE_SIZE = 30

const props = defineProps<{
  searchTerm?: string
}>()

const route = useRoute()
const router = useRouter()

const selectedEntity = ref(
  (route.query.entity as EnumSearchableModels) ?? EnumSearchableModels.Ticket,
)

const {
  filtersByEntity,
  entityFields,
  filterRelationFieldsByEntity,
  currentFilters,
  filterCount,
  currentFiltersQueryParams,
  currentFilterSelector,
  entityFiltersSelector,
  hasActiveFilters,
  setEntityFilters,
  clearCurrentFilters,
  selectedEntityHasFiltersEnabled,
} = useSearchAdvancedFilters(selectedEntity)

const offset = ref(0)

const { sortedByNamePlugins, searchPluginNames } = useSearchPlugins()

const scrollContainerElement = useTemplateRef('scroll-container')
const searchControlsInstance = useTemplateRef('search-controls')

// Single place that writes to the URL — fires on entity switch or filter
// value change. vue-router itself no-ops a replace to the same URL
watch([selectedEntity, currentFiltersQueryParams], ([entity]) => {
  router.replace({
    query: buildSearchRouteQuery({
      entity,
      filters: currentFilters.value,
      baseQuery: getSearchQueryWithoutFilters(route.query),
    }),
  })
})

// Sync URL → state. Runs on initial load and again on every keep-alive
// reactivation, because the cached SearchContent is reused for every /search
// URL (same pageKey) — onBeforeMount alone would miss internal-link returns
// that arrive with different filter query params.
const syncFiltersFromRoute = () => {
  if (!selectedEntityHasFiltersEnabled.value) return

  const queryEntity = (route.query.entity as EnumSearchableModels) ?? EnumSearchableModels.Ticket

  const queryFilters = decodeFilters(route.query, entityFields.value[queryEntity] ?? [])

  if (selectedEntity.value !== queryEntity) selectedEntity.value = queryEntity

  if (isEqual(queryFilters, currentFilters.value)) return

  setEntityFilters(queryEntity, queryFilters)
}

//:TODO useLifeCycle hook when merged and useReactivation
onBeforeMount(syncFiltersFromRoute)
onActivated(syncFiltersFromRoute)

// Object attributes load asynchronously. On a fresh deep-link
// `onBeforeMount` runs with an empty schema, so `decodeFilters` falls back
// to its no-schema passthrough — relation values stay as strings and
// invalid candidates aren't dropped. If the schema isn't ready yet, watch
// for its arrival and re-sync once. Subsequent activations are handled by
// `onActivated`, which already sees a populated schema.
const initialQueryEntity =
  (route.query.entity as EnumSearchableModels) ?? EnumSearchableModels.Ticket
if (!entityFields.value[initialQueryEntity]?.length) {
  // Watch the length, not the array reference — `entityFields` recomputes on
  // every store change and would otherwise fire the once-shot watcher on
  // placeholder identity updates before the schema becomes usable.
  watch(() => entityFields.value[initialQueryEntity]?.length, syncFiltersFromRoute, { once: true })
}

const modelSearchTerm = computed({
  get: () => props.searchTerm,
  set: (searchTerm) => {
    const url = buildSearchDeepLink({
      searchTerm,
      entity: selectedEntity.value,
      filters: currentFilters.value,
      baseQuery: getSearchQueryWithoutFilters(router.currentRoute.value.query),
    })

    router.push(url)
  },
})

const currentSearchTerm = computed(() => modelSearchTerm.value ?? '')

const notVisibleSearchEntities = computed(() =>
  searchPluginNames.value.filter(
    (name) =>
      name !== selectedEntity.value &&
      (!!filtersByEntity[name]?.length || !!currentSearchTerm.value),
  ),
)

const tabContext = computed<TaskbarTabContext>((currentContext) => {
  const newContext = {
    query: currentSearchTerm.value,
    model: selectedEntity.value,
    formIsDirty: hasActiveFilters.value,
    filters: stringifyQuery(currentFiltersQueryParams.value),
    filterCount: filterCount.value,
  }

  if (currentContext && isEqual(newContext, currentContext)) return currentContext

  return newContext
})

const { currentTaskbarTab, currentTaskbarTabUpdate } = useTaskbarTab(tabContext)

watch(
  () => currentTaskbarTab.value?.entity,
  (updatedEntity) => {
    if (!updatedEntity || updatedEntity.__typename !== 'UserTaskbarItemEntitySearch') return

    const updatedQuery = updatedEntity.query ?? ''
    const updatedModel = (updatedEntity.model ??
      EnumSearchableModels.Ticket) as EnumSearchableModels
    const updatedFiltersString = updatedEntity.filters ?? ''

    // When the entity update we just received originated from our own write.
    if (
      updatedQuery === currentSearchTerm.value &&
      updatedModel === selectedEntity.value &&
      updatedFiltersString === stringifyQuery(currentFiltersQueryParams.value)
    )
      return

    const updatedFilterQuery = Object.fromEntries(new URLSearchParams(updatedFiltersString))
    const updatedFilters = decodeFilters(updatedFilterQuery, entityFields.value[updatedModel] ?? [])
    const url = buildSearchDeepLink({
      searchTerm: updatedQuery,
      entity: updatedModel,
      filters: updatedFilters,
      baseQuery: getSearchQueryWithoutFilters(router.currentRoute.value.query),
    })

    router.replace(url).then(syncFiltersFromRoute)
  },
)

watchDebounced(
  tabContext,
  (newValue) => {
    if (!currentTaskbarTab.value) return

    if (isEqual(newValue, omit(currentTaskbarTab.value.entity, '__typename'))) return

    currentTaskbarTabUpdate(currentTaskbarTab.value, newValue)
  },
  { debounce: 500 },
)

const { reachedTop } = useElementScroll(scrollContainerElement as Ref<HTMLElement>)

const { searchTitle: metaTitle } = useSearchTitle(currentSearchTerm, filterCount)

const { pageActive } = usePage({
  metaTitle,
  noTranslateMetaTitle: computed(() => currentSearchTerm.value.length > 0 || filterCount.value > 0),
  onReactivate: () => {
    // oxlint-disable-next-line @eslint/no-use-before-define
    refetchQueries()
  },
})

const searchQueryVariables = computed(() => ({
  search: currentSearchTerm.value,
  limit: PAGE_SIZE,
  onlyIn: selectedEntity.value,
  filter: currentFilterSelector.value,
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
  {
    triggerRefetchOnConnectionReconnect: () => pageActive.value,
  },
)

const searchCountsQuery = new QueryHandler(
  useSearchCountsLazyQuery(
    () => ({
      search: currentSearchTerm.value,
      onlyIn: notVisibleSearchEntities.value,
      filters: entityFiltersSelector.value,
    }),
    {
      context: {
        batch: {
          active: false,
        },
      },
      fetchPolicy: 'cache-and-network', // TODO: for now until the cache handling is implemented
    },
  ),
  {
    triggerRefetchOnConnectionReconnect: () => pageActive.value,
  },
)

const searchResult = detailSearchQuery.result()
const currentSearchCountsResult = searchCountsQuery.result()

// We store the search result to be able to overwrite it
// On entity switch, the result of the previous entity might be reflect and breaks theUI
// Local state can be overwritten so we always clear the result on entity switch
const currentSearchResult = shallowRef(searchResult.value)

const refetchQueries = () => {
  detailSearchQuery.refetch({
    // FIXME: This is a workaround to avoid broken query on re-navigation, we simply include the current variables.
    //   If the taskbar already exists, but the search term is changed, refetch will be called with empty variables.
    //   In parallel, another query with correct variables will be called.
    ...searchQueryVariables.value,
    limit: offset.value + PAGE_SIZE,
  })
  searchCountsQuery.refetch()
}

const searchPlugin = computed(() => searchPluginByName[selectedEntity.value])

const { config } = storeToRefs(useApplicationStore())

const detailSearchHeaders = computed(() =>
  typeof searchPlugin.value.detailSearchHeaders === 'function'
    ? searchPlugin.value.detailSearchHeaders(config.value)
    : searchPlugin.value.detailSearchHeaders,
)

// Per-entity counts, accumulated from both queries. Keeping previous entries
// across an entity switch / refetch is what prevents tab badges from briefly
// flickering to '-' while the next response is in flight.
const searchEntityCurrentCounts = ref<Partial<Record<EnumSearchableModels, number>>>({})

watch(searchResult, (result) => {
  if (result) searchEntityCurrentCounts.value[selectedEntity.value] = result.search.totalCount
  currentSearchResult.value = result
})

watch(currentSearchCountsResult, (countsResult) => {
  countsResult?.searchCounts.forEach(({ model, totalCount }) => {
    if (model !== selectedEntity.value) {
      searchEntityCurrentCounts.value[model] = totalCount
    }
  })
})

const isLoading = detailSearchQuery.loadingWithoutCachedResult()

// Real total for the visible entity — not just the items loaded into the table.
const searchResultTotalCount = computed(() => currentSearchResult.value?.search.totalCount ?? 0)

const searchTabs = computed(() =>
  sortedByNamePlugins.value.map((plugin) => ({
    label: plugin.label,
    key: plugin.name,
    count: searchEntityCurrentCounts.value[plugin.name] ?? '-',
  })),
)

const { forceDetailSearchCacheOnlyFirstPage } = useDetailSearchCache()

const { sort, orderBy, orderDirection, isSorting } = useSorting(
  detailSearchQuery,
  undefined,
  undefined,
  scrollContainerElement,
)

const loadingNewPage = ref(false)

const resetPagination = (variables: Partial<DetailSearchQueryVariables> = {}) => {
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

const {
  checkedTicketIds,
  selectAllActive,
  bulkContext,
  bulkSelector,
  openBulkEditFlyout,
  setOnSuccessCallback,
} = useTicketBulkEdit()

const {
  isActive: isDragAndDropActive,
  cursorPosition,
  dragPreviewData,
  dropSuccessTargetEntity,
} = useDragAndDropBulk(
  {
    checkedTicketIds,
    bulkSelector,
  },
  {
    enabled: computed(() => selectedEntity.value === EnumSearchableModels.Ticket),
  },
)

// Variables that define what the detail search is looking up. A change to
// any of these means we must reset bulk-edit state, trim the previous-page
// apollo cache for the prior variables (so paged results don't leak
// across queries), and restart pagination at offset 0.
const detailCriteria = computed<Pick<DetailSearchQueryVariables, 'search' | 'onlyIn' | 'filter'>>(
  (currentValue) => {
    const updatedValues = {
      search: currentSearchTerm.value,
      onlyIn: selectedEntity.value,
      filter: currentFilterSelector.value,
    }

    return currentValue && isEqual(currentValue, updatedValues) ? currentValue : updatedValues
  },
)

const setNewSearchState = (searchTerm: string) => {
  checkedTicketIds.value.clear()
  selectAllActive.value = false
  bulkContext.value = { searchQuery: searchTerm, searchFilter: currentFilterSelector.value }
  currentSearchResult.value = undefined
}

// Conditions under which each query needs to be running. Detail looks at
// the visible entity only; counts looks at every other entity that has a
// filter, or at every other entity whenever a search term is present.
const shouldDetailRun = computed(() => currentSearchTerm.value.length > 0 || filterCount.value > 0)
const shouldCountsRun = computed(
  () =>
    searchPluginNames.value.length > 1 &&
    (entityFiltersSelector.value.length > 0 || currentSearchTerm.value.length > 0),
)

watch(
  detailCriteria,
  (current, previous) => {
    setNewSearchState(current.search)

    if (!previous) return

    resetPagination({
      search: previous.search,
      onlyIn: previous.onlyIn,
      filter: previous.filter,
    })

    // After a stop/start cycle with the same entity (e.g. clear search term then
    // retype the same term), Vue Apollo retains the cached value in the result ref
    // without triggering a reactive change. The watch(searchResult) callback therefore
    // won't fire and currentSearchResult would be stuck on undefined, so we sync manually!
    if (previous.onlyIn === current.onlyIn)
      nextTick(() => {
        // Only restore when the query is still supposed to be running — i.e. the
        // user retyped the same term.  If shouldDetailRun is false (search was
        // cleared) we must not re-populate from the retained cache value.
        if (
          shouldDetailRun.value &&
          currentSearchResult.value === undefined &&
          searchResult.value !== undefined
        ) {
          currentSearchResult.value = searchResult.value
          searchEntityCurrentCounts.value[selectedEntity.value] =
            searchResult.value.search.totalCount
        }
      })
  },
  { immediate: true },
)

watch(
  shouldDetailRun,
  (run, previousRun) => {
    if (run && detailSearchQuery.isFirstRun()) detailSearchQuery.load()
    else if (run && !previousRun) nextTick(() => detailSearchQuery.start())
    else if (!run && previousRun) {
      detailSearchQuery.stop()
      delete searchEntityCurrentCounts.value[selectedEntity.value]
    }
  },
  { immediate: true },
)

watch(
  shouldCountsRun,
  (run, previousRun) => {
    if (run && searchCountsQuery.isFirstRun()) searchCountsQuery.load()
    else if (run && !previousRun) {
      nextTick(() => {
        searchCountsQuery.start()
        // Same retained-cache issue: if the counts result ref already holds the
        // previous response (stop() didn't clear it), the watcher won't re-fire
        // and counts would stay at '-'. Re-process the result manually.
        nextTick(() => {
          currentSearchCountsResult.value?.searchCounts.forEach(({ model, totalCount }) => {
            if (model !== selectedEntity.value) {
              searchEntityCurrentCounts.value[model] = totalCount
            }
          })
        })
      })
    } else if (!run && previousRun) {
      searchCountsQuery.stop()
      // Strip everything except the visible entity's count — that one
      const visible = searchEntityCurrentCounts.value[selectedEntity.value]
      searchEntityCurrentCounts.value =
        visible !== undefined ? { [selectedEntity.value]: visible } : {}
    }
  },
  { immediate: true },
)

const currentSearchResultCount = computed(
  () => searchEntityCurrentCounts.value[selectedEntity.value],
)

const { visibleSkeletonLoadingCount } = useSkeletonLoadingCount(currentSearchResultCount)

const searchResultItems = computed(() =>
  shouldDetailRun.value
    ? ((currentSearchResult.value?.search.items ?? []) as Record<string, unknown>[])
    : [],
)

const breadcrumbItems = computed(() => [
  { label: __('Search') },
  {
    label: __('Results'),
    isActive: true,
    count: currentSearchResultCount.value,
  },
])

const hasActiveSearch = computed(() => hasActiveFilters.value || currentSearchTerm.value.length > 0)

setOnSuccessCallback(() => {
  resetPagination()
  refetchQueries()
  requestAnimationFrame(() => {
    scrollContainerElement.value?.scrollTo({ top: 0 })
  })
})
</script>

<template>
  <LayoutContent content-padding no-scrollable :breadcrumb-items="breadcrumbItems">
    <template #headerRight>
      <TicketBulkEditButton
        v-if="selectedEntity === EnumSearchableModels.Ticket"
        :checked-ticket-ids="checkedTicketIds"
        :total-count="searchResultTotalCount"
        @open-flyout="openBulkEditFlyout"
      />
    </template>
    <div class="flex h-full flex-col overflow-hidden pt-px" data-test-id="search-container">
      <SearchControls
        ref="search-controls"
        v-model:search="modelSearchTerm"
        v-model:selected-entity="selectedEntity"
        :search-tabs="searchTabs"
        :filters-by-entity="filtersByEntity"
        :entity-fields="entityFields"
        :filter-relation-fields-by-entity="filterRelationFieldsByEntity"
        :filter-count="filterCount"
        :selected-entity-has-filters-enabled="selectedEntityHasFiltersEnabled"
        class="px-4"
        @entity-filters-changed="(entity, value) => setEntityFilters(entity, value)"
        @clear-filters="clearCurrentFilters"
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
          :headers="detailSearchHeaders"
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
              :has-active-search="hasActiveSearch"
              :results="searchResultItems"
              @clear-search-input="() => searchControlsInstance?.clearAndFocusSearch()"
            />
          </template>
        </component>
      </div>

      <DragAndDropBulkWrapper
        v-if="isDragAndDropActive"
        :cursor-position="cursorPosition"
        :preview-data="dragPreviewData"
        :drop-success-target-entity="dropSuccessTargetEntity"
      />
    </div>
  </LayoutContent>
</template>
