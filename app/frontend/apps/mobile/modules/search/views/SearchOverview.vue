<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

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
import CommonButtonPills from '@mobile/components/CommonButtonPills/CommonButtonPills.vue'
import { useSessionStore } from '@shared/stores/session'
import SearchResults from '../components/SearchResults.vue'
import { useSearchPlugins } from '../plugins'
import { useSearchLazyQuery } from '../graphql/searchOverview.api'

interface SearchTypeItem extends MenuItem {
  value: string
}

const props = defineProps<{ type?: string }>()

const route = useRoute()
const router = useRouter()

const searchPlugins = useSearchPlugins()
const { hasPermission } = useSessionStore()

const search = ref(String(route.query.search || ''))
// we need a separate debounced value to not trigger query
const filter = ref(search.value)

const canSearch = computed(() => filter.value.length >= 3)

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
  focusSearch()
}

onMounted(() => {
  focusSearch()
})

const loadByFilter = async (filterQuery: string) => {
  if (!props.type) {
    return
  }
  filter.value = filterQuery
  replaceQuery({ search: filterQuery })
  if (!canSearch.value) {
    return
  }
  searchQuery.abort()

  lastSearches.value = lastSearches.value.filter((item) => item !== filterQuery)
  lastSearches.value.push(filterQuery)
  if (lastSearches.value.length > 5) {
    lastSearches.value.shift()
  }

  searchQuery.load()
}

// load data after a few ms to not overload the api
const { ignoreUpdates } = ignorableWatch(search, debounce(loadByFilter, 400))

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

const types: SearchTypeItem[] = Object.entries(searchPlugins).map(
  ([name, plugin]) => {
    return {
      label: plugin.headerLabel,
      type: 'link',
      value: name,
      icon: plugin.icon,
      iconBg: plugin.iconBg,
      onClick: () => selectType(name),
    }
  },
)
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
      />
      <CommonLink
        link="/"
        class="flex items-center justify-center text-lg text-blue ltr:pl-3 rtl:pr-3"
      >
        {{ $t('Cancel') }}
      </CommonLink>
    </div>
    <CommonButtonPills
      v-if="type"
      :options="types"
      :model-value="type"
      @update:model-value="selectType($event as string)"
    />
    <div v-else class="mt-8 px-4" data-test-id="selectTypesSection">
      <CommonSectionMenu :header-title="__('Search for…')" :items="types" />
    </div>
    <div v-if="loading" class="flex h-14 w-full items-center justify-center">
      <CommonIcon name="loader" animation="spin" />
    </div>
    <div v-else-if="canSearch && type && found[type]?.length">
      <SearchResults :data="found[type]" :type="type" />
    </div>
    <div v-else-if="!canSearch" class="mt-4 px-4">
      {{ $t('Enter more than two characters to get any results…') }}
    </div>
    <div v-else class="mt-4 px-4">
      {{ $t('No entries') }}
    </div>
    <div
      v-if="type && (!found[type]?.length || !canSearch)"
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
            <CommonIcon name="clock" size="small" class="mx-2 text-white/50" />
            <span class="text-base">{{ searchItem }}</span>
          </button>
        </li>
        <li v-if="!lastSearches.length">{{ $t('No previous searches') }}</li>
      </ul>
    </div>
  </div>
</template>
