<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'

import type { KnowledgeBaseAnswerTranslation } from '#shared/graphql/types.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBase/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { visibilityMeta } from '#desktop/components/KnowledgeBase/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { getKnowledgeBaseAnswerLink } from '#desktop/entities/knowledge-base/utils/knowledgeBaseAnswerLink.ts'

import { useListTable } from '../CommonTable/composables/useListTable.ts'

import type { ListTableEmits, ListTableProps, TableAttribute } from '../CommonTable/types.ts'

const props = defineProps<ListTableProps<KnowledgeBaseAnswerTranslation>>()

const emit = defineEmits<ListTableEmits>()

const router = useRouter()

const getLink = (item: ObjectWithId) => {
  const link = getKnowledgeBaseAnswerLink(item as KnowledgeBaseAnswerTranslation)

  return typeof link === 'string' ? link : router.resolve(link).fullPath
}

const { goToItem, goToItemLinkColumn, loadMore, resort, storageKeyId } = useListTable(
  props,
  emit,
  getLink,
)

const tableAttributes: TableAttribute[] = [
  {
    name: 'title',
    label: __('Name'),
    headerPreferences: { noSorting: true },
    columnPreferences: {
      link: goToItemLinkColumn,
      tooltip: (item) => (item as KnowledgeBaseAnswerTranslation).title,
    },
    dataType: 'input',
  },
  {
    name: 'updated_at',
    label: __('Updated at'),
    headerPreferences: { noSorting: true },
    columnPreferences: { alignContent: 'left' },
    dataType: 'datetime',
  },
  {
    name: 'visibility',
    label: __('Visibility'),
    headerPreferences: { noSorting: true },
    columnPreferences: {},
    dataType: 'icon',
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
        :order-by="orderBy"
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
        @sort="resort"
      >
        <template #column-cell-visibility="{ item, isRowSelected }">
          <div class="flex min-w-0 items-center gap-1.5">
            <KnowledgeBaseAnswerIcon
              :visibility="(item as KnowledgeBaseAnswerTranslation).visibility"
              size="tiny"
            />
            <CommonLabel
              class="truncate text-gray-100! group-hover:text-black! group-active:text-white! dark:text-neutral-400! group-hover:dark:text-white!"
              :class="{ 'text-black! dark:text-white!': isRowSelected }"
            >
              {{ $t(visibilityMeta[(item as KnowledgeBaseAnswerTranslation).visibility].label) }}
            </CommonLabel>
          </div>
        </template>
      </CommonAdvancedTable>
    </div>
  </CommonLoader>
</template>
