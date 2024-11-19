<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef, nextTick, watch } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type {
  HistoryRecordEvent,
  HistoryRecordIssuer,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n/index.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useTicketHistoryQuery } from '#desktop/pages/ticket/graphql/queries/ticketHistory.api.ts'

import HistoryEvent from './HistoryEvent.vue'
import HistoryEventHeader from './HistoryEventHeader.vue'
import HistoryEventIssuer from './HistoryEventIssuer.vue'

interface Props {
  ticket: TicketById
}

const { ticket } = defineProps<Props>()

const ticketHistoryQuery = new QueryHandler(
  useTicketHistoryQuery({
    ticketId: ticket.id,
  }),
)
const ticketHistoryQueryResult = ticketHistoryQuery.result()
const ticketHistoryQueryLoading = ticketHistoryQuery.loading()

const ticketHistory = computed(() => {
  return ticketHistoryQueryResult.value?.ticketHistory
})

const isLoadingHistory = computed(() => {
  // Return already true when a history result already exists from the cache, also
  // when maybe a loading is in progress(because of cache + network).
  if (ticketHistory.value !== undefined) return false

  return ticketHistoryQueryLoading.value
})

const historyContainerElement = useTemplateRef('history-container')

watch(
  [historyContainerElement, ticketHistoryQueryLoading],
  (newValue) => {
    if (!newValue || !ticketHistoryQueryResult.value?.ticketHistory.length) {
      return
    }

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
    :header-title="__('Ticket History')"
    header-icon="clock-history"
    size="large"
    name="ticket-history"
    no-close-on-action
    hide-footer
  >
    <CommonLoader :loading="isLoadingHistory" no-transition>
      <div ref="history-container">
        <div
          v-for="(entry, idxAll) in ticketHistory"
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
              'rounded-tr-none':
                idxRecord === entry.records.length - 1 &&
                entry.records.length > 1,
              'border-b-0': idxRecord !== entry.records.length - 1,
              'border-t-0':
                idxRecord === entry.records.length - 1 &&
                entry.records.length > 1,
            }"
            class="rounded-lg rounded-tl-none border border-neutral-100 bg-blue-200 pb-1 dark:border-gray-700 dark:bg-gray-700"
          >
            <HistoryEventIssuer
              :issuer="record.issuer as HistoryRecordIssuer"
            />

            <HistoryEvent
              v-for="(event, idxEvent) in record.events"
              :key="`${event.createdAt}-${idxEvent}`"
              v-tooltip="i18n.dateTimeISO(event.createdAt)"
              :event="event as HistoryRecordEvent"
            />

            <CommonDivider
              v-if="idxRecord !== entry.records.length - 1"
              class="mt-2 px-2"
              alternative-background
            />
          </div>
        </div>
      </div>
    </CommonLoader>
  </CommonFlyout>
</template>
