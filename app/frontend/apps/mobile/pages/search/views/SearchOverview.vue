<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ignorableWatch } from '@vueuse/shared'
import { debounce } from 'lodash-es'
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import type { CommonInputSearchExpose } from '#shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonInputSearch from '#shared/components/CommonInputSearch/CommonInputSearch.vue'
import { useRecentSearches } from '#shared/composables/useRecentSearches.ts'
import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'
import { EnumSearchableModels } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButtonGroup from '#mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import type { CommonButtonOption } from '#mobile/components/CommonButtonGroup/types.ts'
import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import type { MenuItem } from '#mobile/components/CommonSectionMenu/index.ts'

import SearchResults from '../components/SearchResults.vue'
import { useSearchLazyQuery } from '../graphql/queries/searchOverview.api.ts'
import { useSearchPlugins } from '../plugins/index.ts'

import type { LocationQueryRaw } from 'vue-router'

interface SearchTypeItem extends MenuItem {
  value: string
}

const props = defineProps<{ type?: string }>()

const route = useRoute()
const router = useRouter()

const searchPlugins = useSearchPlugins()

const search = ref(String(route.query.search || ''))
// we need a separate debounced value to not trigger query
const filter = ref(search.value)

const canSearch = computed(() => filter.value.length >= 1)

const found = reactive({} as Record<string, Record<string, unknown>[]>)

const { recentSearches, addSearch } = useRecentSearches(5)

const model = computed(() => {
  return props.type
    ? searchPlugins[props.type]?.model
    : EnumSearchableModels.Ticket // default passed by router
})

const searchQuery = new QueryHandler(
  useSearchLazyQuery(
    () => ({
      search: filter.value,
      onlyIn: model.value,
    }),
    () => ({ enabled: canSearch.value }),
  ),
)

const loading = searchQuery.loading()

searchQuery.watchOnResult((data) => {
  if (!props.type) return
  if (!data.search) return

  found[props.type] = data.search.items
})

const replaceQuery = (query: LocationQueryRaw) => {
  return router.replace({
    query: {
      ...route.query,
      ...query,
    },
  })
}

const searchInput = ref<CommonInputSearchExpose>()
const focusSearch = () => searchInput.value?.focus()

const selectType = async (selectedType: string) => {
  await router.replace({ params: { type: selectedType } })

  // focus on tab that was selected
  // it's useful when user selected type from the main screen (without tab controls)
  // and after that we focus on tab controls, so user can easily change current type
  const tabOption = document.querySelector(
    `[data-value="${selectedType}"]`,
  ) as HTMLElement | null
  tabOption?.focus()
}

onMounted(() => {
  focusSearch()
})

const loadByFilter = async (filterQuery: string) => {
  filter.value = filterQuery
  replaceQuery({ search: filterQuery })

  if (!canSearch.value || !props.type) {
    return
  }

  addSearch(filterQuery)

  if (searchQuery.isFirstRun()) {
    searchQuery.load()
  }
}

// load data after a few ms to not overload the api
const debouncedLoad = debounce(loadByFilter, 600)

const { ignoreUpdates } = ignorableWatch(search, async (search) => {
  if (!search || !props.type) {
    await loadByFilter(search)
    return
  }

  await debouncedLoad(search)
})

// load data immidiately when type changes or when recent search selected
watch(
  () => props.type,
  () => loadByFilter(search.value),
  { immediate: true },
)

const selectRecentSearch = async (recentSearch: string) => {
  ignoreUpdates(() => {
    search.value = recentSearch
  })
  focusSearch()
  await loadByFilter(recentSearch)
}

const pluginsArray = Object.entries(searchPlugins).map(([name, plugin]) => ({
  name,
  ...plugin,
}))

const searchPills: CommonButtonOption[] = pluginsArray.map((plugin) => ({
  value: plugin.name,
  label: plugin.headerLabel,
}))

const menuSearchTypes = computed<SearchTypeItem[]>(() =>
  pluginsArray.map((plugin) => {
    return {
      label: plugin.searchLabel,
      labelPlaceholder: [search.value],
      type: 'link',
      value: plugin.name,
      icon: plugin.icon,
      iconBg: plugin.iconBg,
      onClick: () => selectType(plugin.name),
    }
  }),
)

const canShowLastSearches = computed(() => {
  if (loading.value) return false

  return (props.type && !found[props.type]?.length) || !canSearch.value
})

const { headerElement, stickyStyles } = useStickyHeader([
  loading,
  () => !!props.type,
])

const showLoader = computed(() => {
  if (!loading.value) return false
  return !props.type || !found[props.type]
})
</script>

<script lang="ts">
export default {
  beforeRouteEnter(to) {
    const { type } = to.params
    const searchPlugins = useSearchPlugins()

    if (!type) {
      const pluginsArray = Object.entries(searchPlugins)

      // if no type is selected, and only one type is available, select it
      if (pluginsArray.length === 1) {
        return { ...to, params: { type: pluginsArray[0][0] } }
      }

      return undefined
    }

    if (Array.isArray(type) || !searchPlugins[type as string]) {
      return { ...to, params: {} }
    }

    return undefined
  },
}
</script>

<template>
  <div>
    <header ref="headerElement" class="bg-black" :style="stickyStyles.header">
      <div class="flex p-4">
        <CommonInputSearch
          ref="searchInput"
          v-model="search"
          wrapper-class="flex-1"
          class="!h-10"
          :aria-label="$t('Enter search and select a type to search for')"
        />
        <CommonLink
          link="/"
          class="text-blue flex items-center justify-center text-base ltr:pl-3 rtl:pr-3"
        >
          {{ $t('Cancel') }}
        </CommonLink>
      </div>
      <h1 class="sr-only">{{ $t('Search') }}</h1>
      <CommonButtonGroup
        v-if="type"
        class="border-b border-[rgba(255,255,255,0.1)] px-4 pb-4"
        as="tabs"
        :options="searchPills"
        :model-value="type"
        @update:model-value="selectType($event as string)"
      />
      <div
        v-else-if="canSearch"
        class="mt-8 px-4"
        data-test-id="selectTypesSection"
      >
        <CommonSectionMenu
          :header-label="__('Search for…')"
          :items="menuSearchTypes"
        />
      </div>
    </header>
    <div :style="stickyStyles.body">
      <div
        v-if="showLoader"
        class="flex h-14 w-full items-center justify-center"
      >
        <CommonIcon name="loading" animation="spin" />
      </div>
      <div
        v-else-if="canSearch && type && found[type]?.length"
        id="search-results"
        aria-live="polite"
        role="tabpanel"
        :aria-busy="showLoader"
      >
        <SearchResults :data="found[type]" :type="type" />
      </div>
      <div v-else-if="canSearch && type" class="px-4 pt-4">
        {{ $t('No entries') }}
      </div>
      <div
        v-if="canShowLastSearches"
        class="px-4 pt-8"
        data-test-id="recentSearches"
      >
        <div class="text-white/50">{{ $t('Recent searches') }}</div>
        <ul class="pt-3">
          <li
            v-for="searchItem in [...recentSearches].reverse()"
            :key="searchItem"
            class="pb-4"
          >
            <button
              type="button"
              class="flex items-center"
              @click="selectRecentSearch(searchItem)"
            >
              <span>
                <CommonIcon
                  name="clock"
                  size="small"
                  class="mx-2 text-white/50"
                  decorative
                />
              </span>
              <span class="text-left text-base">{{ searchItem }}</span>
            </button>
          </li>
          <li v-if="!recentSearches.length">{{ $t('No recent searches') }}</li>
        </ul>
      </div>
    </div>
  </div>
</template>
