<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import type { CommonInputSearchExpose } from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonInputSearch from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import type { MenuItem } from '@mobile/components/CommonSectionMenu'
import { ignorableWatch } from '@vueuse/shared'
import { useLocalStorage } from '@vueuse/core'
import { QueryHandler } from '@shared/server/apollo/handler'
import type { LocationQueryRaw } from 'vue-router'
import { useRoute, useRouter } from 'vue-router'
import { debounce } from 'lodash-es'
import type { CommonButtonOption } from '@mobile/components/CommonButtonGroup/types'
import CommonButtonGroup from '@mobile/components/CommonButtonGroup/CommonButtonGroup.vue'
import { useSessionStore } from '@shared/stores/session'
import SearchResults from '../components/SearchResults.vue'
import { useSearchPlugins } from '../plugins'
import { useSearchLazyQuery } from '../graphql/queries/searchOverview.api'

interface SearchTypeItem extends MenuItem {
  value: string
}

const LAST_SEARCHES_LENGTH_MAX = 5

const props = defineProps<{ type?: string }>()

const route = useRoute()
const router = useRouter()

const searchPlugins = useSearchPlugins()
const { hasPermission } = useSessionStore()

const search = ref(String(route.query.search || ''))
// we need a separate debounced value to not trigger query
const filter = ref(search.value)

const canSearch = computed(() => filter.value.length >= 1)

const found = reactive({} as Record<string, Record<string, unknown>[]>)
const lastSearches = useLocalStorage<string[]>('lastSearches', [])

const model = computed(() => {
  if (!props.type) return undefined
  return searchPlugins[props.type]?.model
})

const searchQuery = new QueryHandler(
  useSearchLazyQuery(
    () => ({
      search: filter.value,
      onlyIn: model.value,
      isAgent: hasPermission(['ticket.agent']),
    }),
    () => ({ enabled: canSearch.value }),
  ),
)

const loading = searchQuery.loading()

searchQuery.watchOnResult((data) => {
  if (!props.type) return

  found[props.type] = data.search
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

  searchQuery.abort()

  lastSearches.value = lastSearches.value.filter((item) => item !== filterQuery)
  lastSearches.value.push(filterQuery)
  if (lastSearches.value.length > LAST_SEARCHES_LENGTH_MAX) {
    lastSearches.value.shift()
  }

  searchQuery.load()
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

// load data immidiately when type changes or when last search selected
watch(
  () => props.type,
  () => loadByFilter(search.value),
  { immediate: true },
)

const selectLastSearch = async (lastSearch: string) => {
  ignoreUpdates(() => {
    search.value = lastSearch
  })
  focusSearch()
  await loadByFilter(lastSearch)
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
    <div class="flex p-4">
      <CommonInputSearch
        ref="searchInput"
        v-model="search"
        wrapper-class="flex-1"
        :aria-label="$t('Enter search and select a type to search for')"
      />
      <CommonLink
        link="/"
        class="flex items-center justify-center text-lg text-blue ltr:pl-3 rtl:pr-3"
      >
        {{ $t('Cancel') }}
      </CommonLink>
    </div>
    <h1 class="sr-only">{{ $t('Search') }}</h1>
    <CommonButtonGroup
      v-if="type"
      class="border-b border-white/10 px-4 pb-4"
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
    <div v-if="loading" class="flex h-14 w-full items-center justify-center">
      <CommonIcon name="mobile-loading" animation="spin" />
    </div>
    <div
      v-else-if="canSearch && type && found[type]?.length"
      id="search-results"
      aria-live="polite"
      role="tabpanel"
      :aria-busy="loading"
    >
      <SearchResults :data="found[type]" :type="type" />
    </div>
    <div v-else-if="canSearch && type" class="mt-4 px-4">
      {{ $t('No entries') }}
    </div>
    <div
      v-if="canShowLastSearches"
      class="mt-8 px-4"
      data-test-id="lastSearches"
    >
      <div class="text-white/50">{{ $t('Last searches') }}</div>
      <ul class="pt-3">
        <li
          v-for="searchItem in [...lastSearches].reverse()"
          :key="searchItem"
          class="pb-4"
          @click="selectLastSearch(searchItem)"
        >
          <button class="flex items-center">
            <div>
              <CommonIcon
                name="mobile-clock"
                size="small"
                class="mx-2 text-white/50"
                decorative
              />
            </div>
            <span class="text-left text-base">{{ searchItem }}</span>
          </button>
        </li>
        <li v-if="!lastSearches.length">{{ $t('No previous searches') }}</li>
      </ul>
    </div>
  </div>
</template>
