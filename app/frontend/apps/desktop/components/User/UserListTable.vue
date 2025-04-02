<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  EnumObjectManagerObjects,
  type OrganizationConnection,
  type User,
} from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'

import { useListTable } from '../CommonTable/composables/useListTable.ts'

import type { ListTableEmits, ListTableProps } from '../CommonTable/types.ts'

const props = defineProps<ListTableProps<User>>()

const emit = defineEmits<ListTableEmits>()

const getLink = (item: ObjectWithId) => `/users/${getIdFromGraphQLId(item.id)}`

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
      :object="EnumObjectManagerObjects.User"
      :headers="headers"
      :order-by="orderBy"
      :order-direction="orderDirection"
      :group-by="groupBy"
      :reached-scroll-top="reachedScrollTop"
      :scroll-container="scrollContainer"
      :attributes="[
        {
          name: 'login',
          label: __('Login'),
          columnPreferences: {
            link: goToItemLinkColumn,
          },
          dataType: 'input',
        },
      ]"
      :attribute-extensions="{
        organization_ids: {
          headerPreferences: {
            noSorting: true,
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
    >
      <template #column-cell-organization_ids="{ item, isRowSelected }">
        <CommonLabel
          v-tooltip.truncate="
            edgesToArray(item.secondaryOrganizations as OrganizationConnection)
              .map((organization) => organization.name)
              .join(', ') || '-'
          "
          class="block! truncate text-gray-100! group-hover:text-black! group-focus-visible:text-white! group-active:text-white! dark:text-neutral-400! group-hover:dark:text-white!"
          :class="[
            {
              'text-black! dark:text-white!': isRowSelected,
            },
          ]"
        >
          {{
            edgesToArray(item.secondaryOrganizations as OrganizationConnection)
              .map((organization) => organization.name)
              .join(', ') || '-'
          }}
        </CommonLabel>
      </template>
    </CommonAdvancedTable>
  </div>
</template>
