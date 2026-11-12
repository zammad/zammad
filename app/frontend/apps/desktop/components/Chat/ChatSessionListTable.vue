<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  EnumChatSessionState,
  type DetailSearchQuery,
  type EnumOrderDirection,
} from '#shared/graphql/types.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'

import { useListTable } from '../CommonTable/composables/useListTable.ts'

import type { ListTableEmits, ListTableProps, TableAttribute } from '../CommonTable/types.ts'

type ChatSessionResult = Extract<
  DetailSearchQuery['search']['items'][number],
  { __typename: 'ChatSession' }
>

const props = defineProps<ListTableProps<ChatSessionResult>>()

const emit = defineEmits<ListTableEmits>()

const getLink = (item: ObjectWithId) => `/chat/session/${(item as ChatSessionResult).internalId}`

const { goToItem, goToItemLinkColumn, loadMore, resort, storageKeyId } = useListTable(
  props,
  emit,
  getLink,
)

// The number shown is the internal id, while the search sorts by a column of the sessions table.
const NUMBER_COLUMN = 'internal_id'

const resortSessions = (column: string, direction: EnumOrderDirection) =>
  resort(column === NUMBER_COLUMN ? 'id' : column, direction)

const stateLabels: Record<EnumChatSessionState, string> = {
  [EnumChatSessionState.Waiting]: __('Waiting'),
  [EnumChatSessionState.Running]: __('Running'),
  [EnumChatSessionState.Closed]: __('Closed'),
}

const tableAttributes: TableAttribute[] = [
  {
    name: NUMBER_COLUMN,
    label: __('Number'),
    columnPreferences: { link: goToItemLinkColumn },
    dataType: 'input',
  },
  {
    name: 'name',
    label: __('Name'),
    dataType: 'input',
  },
  {
    name: 'state',
    label: __('State'),
    dataType: 'input',
  },
  {
    name: 'created_at',
    label: __('Created at'),
    dataType: 'datetime',
  },
]
</script>

<template>
  <CommonLoader :loading="loading">
    <template #skeleton>
      <CommonTableSkeleton
        :columns="headers.length"
        :load-more="loadingNewPage"
        :rows="skeletonLoadingCount"
      />
    </template>

    <slot v-if="!loading && !items.length" name="empty-list" />

    <div v-else-if="items.length">
      <CommonAdvancedTable
        :caption="caption"
        :headers="headers"
        :order-by="orderBy === 'id' ? NUMBER_COLUMN : orderBy"
        :order-direction="orderDirection"
        :group-by="groupBy"
        :reached-scroll-top="reachedScrollTop"
        :scroll-container="scrollContainer"
        :attributes="tableAttributes"
        :items="items"
        :total-items-count="totalCount"
        :storage-key-id="storageKeyId"
        :max-items="maxItems"
        :is-sorting="resorting"
        @load-more="loadMore"
        @click-row="goToItem"
        @sort="resortSessions"
      >
        <template #column-cell-state="{ item, isRowSelected }">
          <CommonLabel
            class="block! truncate text-normal! group-hover:text-contrast! group-focus-visible:text-white! group-active:text-white! group-active:dark:text-white!"
            :class="{ 'text-contrast!': isRowSelected }"
          >
            {{ $t(stateLabels[(item as ChatSessionResult).sessionState]) }}
          </CommonLabel>
        </template>
      </CommonAdvancedTable>
    </div>
  </CommonLoader>
</template>
