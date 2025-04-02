<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  EnumObjectManagerObjects,
  type Organization,
} from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'

import { useListTable } from '../CommonTable/composables/useListTable.ts'

import type { ListTableEmits, ListTableProps } from '../CommonTable/types.ts'

const props = defineProps<ListTableProps<Organization>>()

const emit = defineEmits<ListTableEmits>()

const getLink = (item: ObjectWithId) =>
  `/organizations/${getIdFromGraphQLId(item.id)}`

const { goToItem, goToItemLinkColumn, loadMore, resort, storageKeyId } =
  useListTable(props, emit, getLink)
</script>

<template>
  <div v-if="loading && !loadingNewPage">
    <slot name="loading">
      <CommonTableSkeleton
        data-test-id="table-skeleton"
        :rows="skeletonLoadingCount"
      />
    </slot>
  </div>

  <template v-else-if="!loading && !items.length">
    <slot name="empty-list" />
  </template>

  <div v-else-if="items.length">
    <CommonAdvancedTable
      :caption="caption"
      :object="EnumObjectManagerObjects.Organization"
      :headers="headers"
      :order-by="orderBy"
      :order-direction="orderDirection"
      :group-by="groupBy"
      :reached-scroll-top="reachedScrollTop"
      :scroll-container="scrollContainer"
      :attribute-extensions="{
        name: {
          columnPreferences: {
            link: goToItemLinkColumn,
          },
        },
      }"
      :items="items"
      :total-items="totalCount"
      :storage-key-id="storageKeyId"
      :max-items="maxItems"
      :is-sorting="resorting"
      @load-more="loadMore"
      @click-row="goToItem"
      @sort="resort"
    />
  </div>
</template>
