<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { refDebounced, watchDebounced } from '@vueuse/shared'
import { computed, toRef } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useRecentSearches } from '#shared/composables/useRecentSearches.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import QuickSearchResultList from '#desktop/components/Search/QuickSearch/QuickSearchResultList/QuickSearchResultList.vue'
import { useUserCurrentRecentViewResetMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentRecentViewReset.api.ts'
import { useUserCurrentRecentViewListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentRecentViewList.api.ts'
import { useUserCurrentRecentViewUpdatesSubscription } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentRecentViewUpdates.api.ts'

import { searchPluginByName } from '../plugins/index.ts'

import { useQuickSearchInput } from './useQuickSearchInput.ts'

const DEBOUNCE_TIME = 500

interface Props {
  collapsed?: boolean
  search: string
}

const props = defineProps<Props>()

const hasSearchInput = computed(() => props.search?.length > 0)

// We need to use the search term for debounce, because otherwise showing the quick search result list
// is too early (which means that already some search is triggered with some first characters).
const debouncedSearchInput = refDebounced(
  toRef(props, 'search'),
  DEBOUNCE_TIME + 50, // Add some more delay to the first entered debounced value.
)

const { isTouchDevice } = useTouchDevice()

const {
  ADD_RECENT_SEARCH_DEBOUNCE_TIME,
  recentSearches,
  addSearch,
  clearSearches,
  removeSearch,
} = useRecentSearches()

const recentViewListQuery = new QueryHandler(
  useUserCurrentRecentViewListQuery({
    limit: 10,
  }),
)

const recentViewListQueryResult = recentViewListQuery.result()

const recentViewListItems = computed(
  () => recentViewListQueryResult.value?.userCurrentRecentViewList ?? [],
)

const recentViewUpdatesSubscription = new SubscriptionHandler(
  useUserCurrentRecentViewUpdatesSubscription(),
)

recentViewUpdatesSubscription.onResult(({ data }) => {
  if (data?.userCurrentRecentViewUpdates) {
    recentViewListQuery.refetch()
  }
})

watchDebounced(() => props.search, addSearch, {
  debounce: ADD_RECENT_SEARCH_DEBOUNCE_TIME,
})

const { waitForConfirmation } = useConfirmation()
const { notify } = useNotifications()

const confirmRemoveRecentSearch = async (searchQuery: string) => {
  const confirmed = await waitForConfirmation(
    __('Are you sure? This recent search will be lost.'),
    { fullscreen: true },
  )

  if (!confirmed) return

  removeSearch(searchQuery)

  notify({
    id: 'recent-search-removed',
    type: NotificationTypes.Success,
    message: __('Recent search was removed successfully.'),
  })
}

const confirmClearRecentSearches = async () => {
  const confirmed = await waitForConfirmation(
    __('Are you sure? Your recent searches will be lost.'),
    { fullscreen: true },
  )

  if (!confirmed) return

  clearSearches()

  notify({
    id: 'recent-searches-cleared',
    type: NotificationTypes.Success,
    message: __('Recent searches were cleared successfully.'),
  })
}

const recentViewResetMutation = new MutationHandler(
  useUserCurrentRecentViewResetMutation(),
)

const confirmClearRecentViewed = async () => {
  const confirmed = await waitForConfirmation(
    __('Are you sure? Your recently viewed items will get lost.'),
    { fullscreen: true },
  )

  if (!confirmed) return

  recentViewResetMutation.send().then(() => {
    notify({
      id: 'recent-viewed-cleared',
      type: NotificationTypes.Success,
      message: __('Recently viewed items were cleared successfully.'),
    })
  })
}

const { resetQuickSearchInputField } = useQuickSearchInput()
</script>

<template>
  <div class="overflow-x-hidden overflow-y-auto px-3 py-2.5 outline-none">
    <QuickSearchResultList
      v-if="debouncedSearchInput && hasSearchInput"
      :search="search"
      :debounce-time="DEBOUNCE_TIME"
    />

    <template
      v-else-if="recentSearches.length > 0 || recentViewListItems.length > 0"
    >
      <CommonSectionCollapse
        v-if="recentSearches.length > 0"
        id="page-recent-searches"
        :title="__('Recent searches')"
        :no-header="collapsed"
        no-collapse
      >
        <template #default="{ headerId }">
          <nav :aria-labelledby="headerId">
            <ul class="m-0 flex flex-col gap-1 p-0">
              <li
                v-for="searchQuery in [...recentSearches].reverse()"
                :key="searchQuery"
                class="group/recent-search flex justify-center"
              >
                <CommonLink
                  class="relative flex grow items-center gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:no-underline!"
                  :link="`/search/${searchQuery}`"
                  internal
                  @click="resetQuickSearchInputField"
                >
                  <CommonIcon name="search" size="tiny" />
                  <CommonLabel class="gap-2 text-white!">
                    {{ searchQuery }}
                  </CommonLabel>
                  <CommonButton
                    :aria-label="$t('Delete this recent search')"
                    :class="{
                      'opacity-0 transition-opacity': !isTouchDevice,
                    }"
                    class="absolute end-2 top-3 justify-end group-hover/recent-search:opacity-100 focus:opacity-100"
                    icon="x-lg"
                    size="small"
                    variant="remove"
                    @click.stop.prevent="confirmRemoveRecentSearch(searchQuery)"
                  />
                </CommonLink>
              </li>
            </ul>
            <div class="mt-2 mb-1 flex justify-end">
              <CommonLink
                link="#"
                size="small"
                @click="confirmClearRecentSearches"
              >
                {{ $t('Clear recent searches') }}
              </CommonLink>
            </div>
          </nav>
        </template>
      </CommonSectionCollapse>

      <CommonSectionCollapse
        v-if="recentViewListItems.length > 0"
        id="page-recently-viewed"
        :title="__('Recently viewed')"
        :no-header="collapsed"
        no-collapse
      >
        <template #default="{ headerId }">
          <nav :aria-labelledby="headerId">
            <ul class="m-0 flex flex-col gap-1 p-0">
              <li
                v-for="item in recentViewListItems"
                :key="item.id"
                class="relative"
              >
                <component
                  :is="
                    searchPluginByName[item.__typename!].quickSearchComponent
                  "
                  :item="item"
                  mode="recently-viewed"
                  @click="resetQuickSearchInputField"
                />
              </li>
            </ul>
            <div class="mt-2 mb-1 flex justify-end">
              <CommonLink
                link="#"
                size="small"
                @click="confirmClearRecentViewed"
              >
                {{ $t('Clear recently viewed') }}
              </CommonLink>
            </div>
          </nav>
        </template>
      </CommonSectionCollapse>
    </template>
    <CommonLabel v-else>
      {{
        $t('Start typing e.g. the name of a ticket, an organization or a user.')
      }}
    </CommonLabel>
  </div>
</template>
