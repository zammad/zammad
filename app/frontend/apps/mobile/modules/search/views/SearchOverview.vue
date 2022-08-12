<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onMounted, reactive, ref, watch } from 'vue'
import type { CommonInputSearchExpose } from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonInputSearch from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import type { MenuItem } from '@mobile/components/CommonSectionMenu'
import { ignorableWatch } from '@vueuse/shared'
import { useLocalStorage } from '@vueuse/core'
import type { LocationQueryRaw } from 'vue-router'
import { useRoute, useRouter } from 'vue-router'
import { debounce } from 'lodash-es'
import { TicketState } from '@shared/entities/ticket/types'
import CommonButtonPills from '@mobile/components/CommonButtonPills/CommonButtonPills.vue'
import SearchResults from '../components/SearchResults.vue'
import { useSearchPlugins } from '../plugins'

interface SearchTypeItem extends MenuItem {
  value: string
}

const props = defineProps<{ type?: string }>()

const route = useRoute()
const router = useRouter()

const searchPlugins = useSearchPlugins()

const search = ref(String(route.query.search || ''))

// TODO 2022-06-02 Sheremet V.A. Remove when API is implemented
// TODO base on actual values
const mockData = {
  ticket: [
    {
      id: '100423',
      // eslint-disable-next-line zammad/zammad-detect-translatable-string
      title: 'Client requests return',
      number: '100423',
      state: TicketState.Open,
      priority: {
        name: 'high',
        uiColor: 'high-priority',
      },
      owner: {
        firstname: 'Jerome',
        lastname: 'Miller',
      },
      updatedAt: new Date(2022, 2, 10).toISOString(),
      updatedBy: {
        id: 'hleb',
        firstname: 'Jerome',
        lastname: 'Miller',
      },
    },
  ],
  customer: [],
  organization: [
    {
      id: '1004234',
      name: 'spriptsread.co',
      members: [
        {
          firstname: 'Jerome',
          lastname: 'Miller',
        },
        {
          firstname: 'John',
          lastname: 'Sky',
        },
        {
          firstname: 'John',
          lastname: 'Sky',
        },
      ],
      ticketsCount: 2,
      active: true,
      updatedAt: new Date(2022, 2, 10).toISOString(),
      updatedBy: {
        id: 'hleb',
        firstname: 'Jerome',
        lastname: 'Miller',
      },
    },
  ],
}

const found = reactive(
  Object.keys(searchPlugins).reduce((acc, name) => {
    // TODO 2022-06-02 Sheremet V.A. Remove when API is implemented
    // @ts-expect-error TODO remove
    acc[name] = mockData[name]
    return acc
  }, {} as Record<string, Record<string, unknown>[]>),
)
const loading = ref(false)
const lastSearches = useLocalStorage<string[]>('lastSearches', [])

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

const loadByFilter = async (filter: string) => {
  if (!props.type) {
    return
  }
  if (filter.length < 3) {
    // todo clear data, show nothing?
    return
  }
  replaceQuery({ search: filter })
  lastSearches.value = lastSearches.value.filter((item) => item !== filter)
  lastSearches.value.push(filter)
  if (lastSearches.value.length > 5) {
    lastSearches.value.shift()
  }
  // TODO call api
  loading.value = true
  try {
    await new Promise((resolve) => {
      setTimeout(resolve, 200)
    })
  } finally {
    loading.value = false
  }
}

// load data after a few ms to not overload the api
const { ignoreUpdates } = ignorableWatch(search, debounce(loadByFilter, 500))

// load data immidiately when type changed or when last search selected
watch(
  () => props.type,
  () => loadByFilter(search.value),
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
      label: plugin.headerTitle,
      type: 'link',
      value: name,
      onClick: () => selectType(name),
    }
  },
)
</script>

<script lang="ts">
export default {
  beforeRouteEnter(to) {
    const { type } = to.params
    if (!type) return undefined

    const searchPlugins = useSearchPlugins()
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
      <CommonSectionMenu :header-label="$t('Search…')" :items="types" />
    </div>
    <div v-if="loading" class="flex h-14 w-full items-center justify-center">
      <CommonIcon name="loader" animation="spin" />
    </div>
    <div
      v-else-if="type && !found[type]?.length"
      class="mt-8 px-4"
      data-test-id="lastSearches"
    >
      <div class="text-white/50">{{ $t('Last searches') }}</div>
      <ul class="pt-3">
        <li
          v-for="searchItem in [...lastSearches].reverse()"
          :key="searchItem"
          class="flex cursor-pointer items-center pb-4"
          @click="selectLastSearch(searchItem)"
        >
          <CommonIcon name="clock" size="small" class="mx-2 text-white/50" />
          <span class="text-base">{{ searchItem }}</span>
        </li>
        <li v-if="!lastSearches.length">{{ $t('No previous searches') }}</li>
      </ul>
    </div>
    <div v-else-if="type && found[type]?.length" class="px-4">
      <SearchResults :data="found[type]" :type="type" />
    </div>
  </div>
</template>
