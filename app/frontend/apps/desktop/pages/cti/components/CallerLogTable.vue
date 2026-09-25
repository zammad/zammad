<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import CommonTableSkeleton from '#desktop/components/CommonTable/Skeleton/CommonTableSkeleton.vue'
import type {
  ListTableProps,
  TableAdvancedItem,
  TableAttribute,
} from '#desktop/components/CommonTable/types.ts'
import { useCallerLogDoneToggle } from '#desktop/entities/cti/composables/useCallerLogDoneToggle.ts'

import { useCallerUserCreate } from '../composables/useCallerUserCreate.ts'
import {
  formatDuration,
  getCallerLogStatus,
  getCallerLogStatusDisplay,
  isCallerLogDoneDisabled,
} from '../utils/callerLog.ts'

import CallerLogParticipant from './CallerLogParticipant.vue'

import type { CallerLogEntry } from '../types.ts'

const props = defineProps<ListTableProps<CallerLogEntry>>()

const userId = toRef(useSessionStore(), 'userId')

const application = useApplicationStore()

const nameFormat = computed(() => application.config.user_name_format)

const storageKeyId = computed(() => `${userId.value}-table-headers-${props.tableId}`)

const loadMore = async () => {
  await props.onLoadMore?.()
}

// The query has no sort arguments, so every column stays unsortable.
const tableAttributes: TableAttribute[] = [
  {
    name: 'done',
    label: __('Handled'),
    headerPreferences: { displayWidth: 40, hideLabel: true, noResize: true },
    columnPreferences: { alignContent: 'center' },
    dataType: 'input',
  },
  {
    name: 'from',
    label: __('From'),
    headerPreferences: { minimumWidth: 200, noSorting: true },
    columnPreferences: {},
    dataType: 'input',
  },
  {
    name: 'to',
    label: __('To'),
    headerPreferences: { minimumWidth: 200, noSorting: true },
    columnPreferences: {},
    dataType: 'input',
  },
  {
    name: 'status',
    label: __('Status'),
    headerPreferences: { displayWidth: 200, noSorting: true },
    columnPreferences: {},
    dataType: 'input',
  },
  {
    name: 'waiting',
    label: __('Waiting'),
    headerPreferences: { displayWidth: 100, noSorting: true },
    columnPreferences: { alignContent: 'left' },
    dataType: 'input',
  },
  {
    name: 'duration',
    label: __('Duration'),
    headerPreferences: { displayWidth: 100, noSorting: true },
    columnPreferences: {},
    dataType: 'input',
  },
  {
    name: 'created_at',
    label: __('Time'),
    headerPreferences: { displayWidth: 200, noSorting: true },
    columnPreferences: { alignContent: 'left' },
    dataType: 'datetime',
  },
]

const getRowClass = (item: TableAdvancedItem) => ({
  'opacity-50': (item as unknown as CallerLogEntry).done,
})

const getDirectionLabel = (entry: CallerLogEntry) =>
  entry.direction === 'in' ? __('Inbound call') : __('Outbound call')

const { toggleDone } = useCallerLogDoneToggle()

const reactiveNow = useReactiveNow()

const isDoneDisabled = (item: TableAdvancedItem) =>
  isCallerLogDoneDisabled(item as unknown as CallerLogEntry, reactiveNow.value)

const toggleItemDone = (item: TableAdvancedItem) => {
  if (isDoneDisabled(item)) return

  toggleDone(item as unknown as CallerLogEntry)
}

// The checkbox has no visible label, so the tooltip names it in every state, including
//   the locked one, where it says why the call cannot be marked yet.
const getDoneLabel = (item: TableAdvancedItem) => {
  if (isDoneDisabled(item))
    return __('Can be marked as handled once the call has ended or is a minute old')

  return item.done ? __('Mark as not handled') : __('Mark as handled')
}

const { openCallerUserCreateFlyout } = useCallerUserCreate()
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
        :reached-scroll-top="reachedScrollTop"
        :scroll-container="scrollContainer"
        :attributes="tableAttributes"
        :items="items"
        :total-items-count="totalCount"
        :storage-key-id="storageKeyId"
        :max-items="maxItems"
        :row-class="getRowClass"
        dynamic-row-height
        @load-more="loadMore"
      >
        <template #column-cell-done="{ item }">
          <!-- eslint-disable-next-line vuejs-accessibility/interactive-supports-focus-->
          <div
            :id="`item-done-${item.id}`"
            v-tooltip="$t(getDoneLabel(item))"
            role="checkbox"
            class="group/checkbox flex size-full cursor-pointer items-center justify-center text-stone-200 group-hover:text-black! group-active:text-white! focus-visible:outline-none dark:text-neutral-500 group-hover:dark:text-white!"
            :class="{
              'text-gray-100! dark:text-neutral-400!': item.done,
              'cursor-not-allowed! opacity-50 group-hover:text-gray-100! group-hover:dark:text-neutral-400!':
                isDoneDisabled(item),
            }"
            :tabindex="isDoneDisabled(item) ? -1 : 0"
            :aria-disabled="isDoneDisabled(item)"
            :aria-checked="!!item.done"
            @click="toggleItemDone(item)"
            @keydown.enter="toggleItemDone(item)"
            @keydown.space.prevent="toggleItemDone(item)"
          >
            <CommonIcon
              decorative
              class="shrink-0 group-focus-visible/checkbox:rounded-xs group-focus-visible/checkbox:outline group-focus-visible/checkbox:outline-offset-1 group-focus-visible/checkbox:outline-blue-800"
              size="xs"
              :name="item.done ? 'check-square' : 'square'"
            />
          </div>
        </template>
        <template #column-cell-from="{ item }">
          <CallerLogParticipant
            :matches="(item as CallerLogEntry).fromMatches"
            :name-format="nameFormat"
            :number="(item as CallerLogEntry).from"
            :number-pretty="(item as CallerLogEntry).fromPretty"
            :comment="(item as CallerLogEntry).fromComment"
            :is-external="(item as CallerLogEntry).direction === 'in'"
            :is-done="(item as CallerLogEntry).done"
            @user-create="openCallerUserCreateFlyout"
          />
        </template>

        <template #column-cell-to="{ item }">
          <CallerLogParticipant
            :matches="(item as CallerLogEntry).toMatches"
            :name-format="nameFormat"
            :number="(item as CallerLogEntry).to"
            :number-pretty="(item as CallerLogEntry).toPretty"
            :comment="(item as CallerLogEntry).toComment"
            :is-external="(item as CallerLogEntry).direction === 'out'"
            :is-done="(item as CallerLogEntry).done"
            @user-create="openCallerUserCreateFlyout"
          />
        </template>

        <template #column-cell-status="{ item }">
          <div
            v-if="getCallerLogStatus(item as CallerLogEntry)"
            class="flex min-w-0 items-center gap-x-1.25"
          >
            <CommonIcon
              class="shrink-0"
              :class="getCallerLogStatusDisplay(item as CallerLogEntry).iconClass"
              :name="getCallerLogStatusDisplay(item as CallerLogEntry).icon"
              :label="$t(getDirectionLabel(item as CallerLogEntry))"
              size="tiny"
            />
            <CommonLabel
              class="line-clamp-1! break-all"
              :class="getCallerLogStatusDisplay(item as CallerLogEntry).labelClass"
            >
              {{ $t(getCallerLogStatus(item as CallerLogEntry)) }}
            </CommonLabel>
          </div>
          <template v-else>-</template>
        </template>

        <template #column-cell-waiting="{ item }">
          <CommonLabel class="text-gray-100 dark:text-neutral-400">
            {{ formatDuration((item as CallerLogEntry).durationWaitingTime) || '-' }}
          </CommonLabel>
        </template>

        <template #column-cell-duration="{ item }">
          <CommonLabel class="text-gray-100 dark:text-neutral-400">
            {{ formatDuration((item as CallerLogEntry).durationTalkingTime) || '-' }}
          </CommonLabel>
        </template>
      </CommonAdvancedTable>
    </div>
  </CommonLoader>
</template>
