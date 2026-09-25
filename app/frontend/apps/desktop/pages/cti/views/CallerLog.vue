<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, type Ref, toRef, useTemplateRef } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'
import { useSkeletonLoadingCount } from '#desktop/components/CommonTable/composables/useSkeletonLoadingCount.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'

import CallerLogNotConfigured from '../components/CallerLogNotConfigured.vue'
import CallerLogTable from '../components/CallerLogTable.vue'
import { CALLER_LOG_PAGE_SIZE, useCallerLog } from '../composables/useCallerLog.ts'

const MAX_ITEMS = 1000

const TABLE_HEADERS = ['done', 'from', 'to', 'status', 'waiting', 'duration', 'created_at']

const breadcrumbItems = [{ label: __('Caller log') }]

const config = toRef(useApplicationStore(), 'config')

const isConfigured = computed(() =>
  Boolean(
    config.value.cti_integration ||
    config.value.sipgate_integration ||
    config.value.placetel_integration,
  ),
)

const { logs, totalCount, loading, error, pagination, fetchNextPage } = useCallerLog(isConfigured)

const scrollContainer = useTemplateRef('scroll-container')

const { reachedTop } = useElementScroll(scrollContainer as Ref<HTMLDivElement>)

useScrollPosition(scrollContainer)

const { visibleSkeletonLoadingCount } = useSkeletonLoadingCount(
  computed(() => CALLER_LOG_PAGE_SIZE),
)
</script>

<template>
  <LayoutContent class="relative" :breadcrumb-items="breadcrumbItems" no-scrollable content-padding>
    <CallerLogNotConfigured v-if="!isConfigured" />

    <CommonEmptyMessage
      v-else-if="error"
      class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
      :title="$t('Caller log unavailable')"
      :text="$t('The caller log could not be loaded. Please try again later.')"
      icon="exclamation-triangle"
    />

    <div
      v-else
      ref="scroll-container"
      class="h-full overflow-y-auto px-4 pb-4 focus-visible:outline-none"
    >
      <CallerLogTable
        table-id="caller-log"
        :caption="$t('Caller log')"
        :headers="TABLE_HEADERS"
        :items="logs"
        :total-count="totalCount"
        :max-items="MAX_ITEMS"
        :loading="loading"
        :loading-new-page="pagination.loadingNewPage"
        :skeleton-loading-count="visibleSkeletonLoadingCount"
        :reached-scroll-top="reachedTop"
        :scroll-container="scrollContainer"
        @load-more="fetchNextPage"
      >
        <template #empty-list>
          <CommonEmptyMessage
            class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
            :title="$t('Empty caller log')"
            :text="$t('No calls to process.')"
            with-illustration
          />
        </template>
      </CallerLogTable>
    </div>
  </LayoutContent>
</template>
