<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef, watch } from 'vue'

import type { AvatarUser } from '#shared/components/CommonUserAvatar/types.ts'
import ObjectAttributeContent from '#shared/components/ObjectAttributes/ObjectAttribute.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { TicketByList } from '#shared/entities/ticket/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'
import CommonTicketPriorityIndicatorIcon from '#desktop/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicatorIcon.vue'
import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicatorIcon.vue'
import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'

import { useListTable } from '../CommonTable/composables/useListTable.ts'

import { useTicketBulkEdit } from './TicketBulkEditFlyout/useTicketBulkEdit.ts'

import type { ListTableEmits, ListTableProps } from '../CommonTable/types.ts'

const props = defineProps<ListTableProps<TicketByList>>()

const emit = defineEmits<ListTableEmits>()

const getLink = (item: ObjectWithId) => `/tickets/${getIdFromGraphQLId(item.id)}`

const { goToItem, goToItemLinkColumn, loadMore, resort, storageKeyId } = useListTable(
  props,
  emit,
  getLink,
)

const config = toRef(useApplicationStore(), 'config')

/**
 * User can only perform one bulk update task at a time
 */
const {
  bulkEditActive,
  checkedTicketIds,
  selectAllActive,
  isBulkTaskRunning,
  bulkCount,
  bulkHasMoreItems,
} = useTicketBulkEdit()

watch(selectAllActive, (newValue) => {
  if (!newValue) {
    bulkCount.value = 0
    bulkHasMoreItems.value = false

    return
  }

  if (props.totalCount > props.maxItems) {
    bulkCount.value = props.maxItems
    bulkHasMoreItems.value = true
  } else {
    bulkCount.value = props.totalCount
    bulkHasMoreItems.value = false
  }
})

const userPopoverSlots: {
  slotName: string
  ticketAttribute: keyof TicketByList
}[] = [
  { slotName: 'column-cell-customer_id', ticketAttribute: 'customer' },
  { slotName: 'column-cell-owner_id', ticketAttribute: 'owner' },
]
</script>

<template>
  <CommonTableSkeleton
    :loading="loading"
    :loading-new-page="loadingNewPage"
    :rows="skeletonLoadingCount"
  >
    <slot v-if="!loading && !items.length" name="empty-list" />

    <div v-else-if="items.length">
      <CommonAdvancedTable
        v-model:checked-item-ids="checkedTicketIds"
        v-model:select-all-active="selectAllActive"
        :has-bulk-action="bulkEditActive"
        :disable-bulk-action="isBulkTaskRunning"
        :caption="caption"
        :object="EnumObjectManagerObjects.Ticket"
        :headers="headers"
        :order-by="orderBy"
        :order-direction="orderDirection"
        :group-by="groupBy"
        :reached-scroll-top="reachedScrollTop"
        :scroll-container="scrollContainer"
        :attributes="[
          {
            name: 'priorityIcon',
            label: __('Priority icon'),
            headerPreferences: {
              noResize: true,
              hideLabel: true,
              displayWidth: 21,
              noSorting: true,
              headerClass: 'p-0!',
            },
            columnPreferences: {
              noPadding: true,
              alignContent: 'left',
            },
            dataType: 'icon',
          },
          {
            name: 'stateIcon',
            label: __('State icon'),
            headerPreferences: {
              noResize: true,
              hideLabel: true,
              displayWidth: 25,
              noSorting: true,
              headerClass: 'p-0!',
            },
            columnPreferences: {
              noPadding: true,
              alignContent: 'center',
            },
            dataType: 'icon',
          },
        ]"
        :attribute-extensions="{
          title: {
            columnPreferences: {
              link: goToItemLinkColumn,
            },
          },
          number: {
            label: config.ticket_hook,
            columnPreferences: {
              link: goToItemLinkColumn,
            },
          },
        }"
        :items="items"
        :total-items-count="totalCount"
        :storage-key-id="storageKeyId"
        :max-items="maxItems"
        :is-sorting="resorting"
        @load-more="loadMore"
        @click-row="goToItem"
        @sort="resort"
      >
        <template #column-cell-priorityIcon="{ item, isRowSelected }">
          <CommonTicketPriorityIndicatorIcon
            :data-priority-ui-color="(item as TicketByList).priority?.uiColor ?? undefined"
            :ui-color="(item as TicketByList).priority?.uiColor"
            with-text-color
            class="shrink-0 outline-offset-0! group-hover:text-black group-active:text-white group-hover:dark:text-white group-active:dark:text-white"
            :class="{
              'text-black! dark:text-white!': isRowSelected,
            }"
          />
        </template>
        <template
          v-for="{ slotName, ticketAttribute } in userPopoverSlots"
          :key="slotName"
          #[slotName]="{ item, isRowSelected, attribute }"
        >
          <UserPopoverWithTrigger
            :popover-config="{ orientation: 'autoHorizontal' }"
            :user="(item as TicketByList)[ticketAttribute] as AvatarUser"
            class="w-full outline-none!"
            no-trigger-link
          >
            <CommonLabel
              class="block! shrink-0 truncate outline-offset-0! group-hover:text-black group-active:text-white group-hover:dark:text-white group-active:dark:text-white"
              :class="{
                'text-black! dark:text-white!': isRowSelected,
              }"
            >
              <ObjectAttributeContent
                mode="table"
                :attribute="attribute as unknown as ObjectAttribute"
                :object="item"
              />
            </CommonLabel>
          </UserPopoverWithTrigger>
        </template>
        <template #column-cell-organization_id="{ item, isRowSelected, attribute }">
          <OrganizationPopoverWithTrigger
            :popover-config="{ orientation: 'autoHorizontal' }"
            :organization="(item as TicketByList).organization!"
            class="w-full outline-none!"
            no-link
          >
            <CommonLabel
              class="block! shrink-0 truncate outline-offset-0! group-hover:text-black group-active:text-white group-hover:dark:text-white group-active:dark:text-white"
              :class="{
                'text-black! dark:text-white!': isRowSelected,
              }"
            >
              <ObjectAttributeContent
                mode="table"
                :attribute="attribute as unknown as ObjectAttribute"
                :object="item"
              />
            </CommonLabel>
          </OrganizationPopoverWithTrigger>
        </template>
        <template #column-cell-stateIcon="{ item, isRowSelected }">
          <CommonIcon
            v-if="item.aiAgentRunning"
            role="status"
            :aria-label="$t('Currently processing this ticket…')"
            class="animate-spin"
            size="tiny"
            name="check-circle-no-ai"
          />
          <CommonTicketStateIndicatorIcon
            v-else
            :data-state-color-code="(item as TicketByList).stateColorCode"
            class="shrink-0 outline-offset-0! group-hover:text-black group-active:text-white group-hover:dark:text-white group-active:dark:text-white"
            :class="{
              'text-black! dark:text-white!': isRowSelected,
            }"
            :color-code="(item as TicketByList).stateColorCode"
            :label="(item as TicketByList).state.name"
            :aria-labelledby="(item as TicketByList).id"
            icon-size="tiny"
          />
        </template>
      </CommonAdvancedTable>
    </div>
  </CommonTableSkeleton>
</template>
