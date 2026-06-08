<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef, nextTick, watch } from 'vue'

import type {
  EnumObjectManagerObjects,
  HistoryGroup,
  HistoryRecordEvent,
  HistoryRecordIssuer,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

import HistoryEvent from './HistoryEvent.vue'
import HistoryEventHeader from './HistoryEventHeader.vue'
import HistoryEventIssuer from './HistoryEventIssuer.vue'

import type { OperationVariables } from '@apollo/client/core'
import type { UseQueryReturn } from '@vue/apollo-composable'

interface HistoryQueryResult {
  [key: string]: Array<HistoryGroup> | undefined
}

export interface Props {
  name: string
  query: () => UseQueryReturn<HistoryQueryResult, OperationVariables>
  type: EnumObjectManagerObjects
  title?: string
}

const props = defineProps<Props>()

const historyQuery = new QueryHandler(props.query())
const historyQueryResult = historyQuery.result()

const historyData = computed(() =>
  historyQueryResult.value
    ? (Object.values(historyQueryResult.value).flat() as HistoryGroup[])
    : null,
)

const isLoadingHistory = historyQuery.loadingWithoutCachedResult()

const historyContainerElement = useTemplateRef('history-container')

watch(
  [historyContainerElement, isLoadingHistory],
  (newValue) => {
    if (!newValue) return

    nextTick(() => {
      historyContainerElement.value?.scrollIntoView({
        behavior: 'instant',
        block: 'end',
      })
    })
  },
  { flush: 'post' },
)
</script>

<template>
  <CommonFlyout
    :header-title="title ?? __('History')"
    header-icon="clock-history"
    size="large"
    :name="name"
    hide-footer
  >
    <CommonLoader :loading="isLoadingHistory" no-transition>
      <div ref="history-container">
        <div
          v-for="(entry, idxAll) in historyData"
          :key="`${entry.createdAt}-${idxAll}`"
          class="my-3"
          :class="{
            'mt-0': idxAll === 0,
          }"
        >
          <HistoryEventHeader :created-at="entry.createdAt" />

          <div
            v-for="(record, idxRecord) in entry.records"
            :key="`${'id' in record.issuer ? record.issuer.id : record.issuer.klass}-${idxRecord}`"
            :class="{
              'rounded-b-none': idxRecord !== entry.records.length - 1,
              'rounded-tr-none': idxRecord === entry.records.length - 1 && entry.records.length > 1,
              'border-b-0': idxRecord !== entry.records.length - 1,
              'border-t-0': idxRecord === entry.records.length - 1 && entry.records.length > 1,
            }"
            class="rounded-lg rounded-tl-none border border-neutral-100 bg-blue-200 pb-1 dark:border-gray-700 dark:bg-gray-700"
          >
            <HistoryEventIssuer :issuer="record.issuer as HistoryRecordIssuer" />

            <HistoryEvent
              v-for="(event, idxEvent) in record.events"
              :key="`${event.createdAt}-${idxEvent}`"
              v-tooltip="i18n.dateTimeISO(event.createdAt)"
              :event="event as HistoryRecordEvent"
            />

            <CommonDivider
              v-if="idxRecord !== entry.records.length - 1"
              class="mt-2 px-2"
              variant="gray"
              alternative-background
            />
          </div>
        </div>
      </div>
    </CommonLoader>
  </CommonFlyout>
</template>
