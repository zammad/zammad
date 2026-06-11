<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { until } from '@vueuse/core'
import { computed } from 'vue'

import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'
import type { NavigationTab } from '#desktop/components/CommonTabs/types.ts'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import DragAndDropBulkWrapper from '#desktop/components/Ticket/DragAndDropBulk/DragAndDropBulkWrapper.vue'
import { useDragAndDropBulk } from '#desktop/components/Ticket/DragAndDropBulk/useDragAndDropBulk.ts'
import TicketBulkEditButton from '#desktop/components/Ticket/TicketBulkEditButton.vue'
import { useTicketBulkEdit } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'
import TicketList from '#desktop/pages/ticket-overviews/components/TicketList.vue'
import TicketOverviewsSidebar from '#desktop/pages/ticket-overviews/components/TicketOverviewsSidebar.vue'
import { useTicketOverviews } from '#desktop/pages/ticket-overviews/composables/useTicketOverviews.ts'

interface Props {
  overviewLink?: string
}

const props = defineProps<Props>()

defineOptions({
  async beforeRouteEnter(to) {
    const {
      overviews,
      overviewsLoading,
      setCurrentTicketOverviewLink,
      currentTicketOverviewLink,
      overviewsByLink,
    } = useTicketOverviews()

    await until(() => overviewsLoading.value).toBe(false)

    const overviewLink = to.params.overviewLink as string

    if (overviewLink in overviewsByLink.value || overviews.value.length === 0) {
      setCurrentTicketOverviewLink(overviewLink || '')
      return true
    }

    const nextOverviewLink = currentTicketOverviewLink.value || overviews.value[0].link
    setCurrentTicketOverviewLink(nextOverviewLink)

    return {
      name: 'TicketOverview',
      params: { overviewLink: nextOverviewLink },
    }
  },
  beforeRouteUpdate(to) {
    const { currentTicketOverviewLink, overviews, setCurrentTicketOverviewLink } =
      useTicketOverviews()

    if (to.params.overviewLink) {
      setCurrentTicketOverviewLink(to.params.overviewLink as string)
      return true
    }

    const nextOverviewLink = currentTicketOverviewLink.value || overviews.value[0].link
    setCurrentTicketOverviewLink(nextOverviewLink)

    return {
      name: 'TicketOverview',
      params: { overviewLink: nextOverviewLink },
    }
  },
})

const { overviews, overviewsByLink, hasOverviews, overviewsTicketCountById } = useTicketOverviews()

const currentOverview = computed(() => overviewsByLink.value[props.overviewLink || ''])

const overviewsTabs = computed<NavigationTab[]>(() =>
  overviews.value?.map((item) => ({
    label: item.name,
    key: item.id,
    default: item.link === props.overviewLink,
    count: overviewsTicketCountById.value[item.id],
    link: item.link,
  })),
)

const activeTab = computed(() => currentOverview.value?.id || '')

const currentOverviewCount = computed(
  () => overviewsTicketCountById.value[currentOverview.value?.id],
)

const breadcrumbItems = computed(() => [
  {
    label: __('Overviews'),
    route: '/tickets/view',
  },
  {
    label: currentOverview.value?.name,
    count: currentOverviewCount.value,
  },
])

const { checkedTicketIds, openBulkEditFlyout, bulkSelector } = useTicketBulkEdit()

const {
  isActive: isDragAndDropActive,
  cursorPosition,
  dragPreviewData,
  dropSuccessTargetEntity,
} = useDragAndDropBulk({
  checkedTicketIds,
  bulkSelector,
})
</script>

<template>
  <div class="h-full" :class="{ 'grid grid-cols-1 lg:grid-cols-[260px_1fr]': hasOverviews }">
    <LayoutSidebar
      v-if="hasOverviews"
      id="ticket-overviews"
      class="hidden lg:flex"
      :aria-label="$t('second level navigation sidebar')"
      background-variant="secondary"
      :name="SidebarName.TicketOverviews"
    >
      <TicketOverviewsSidebar />
    </LayoutSidebar>

    <LayoutContent
      class="relative"
      :active-tab="activeTab"
      :breadcrumb-items="currentOverview ? breadcrumbItems : undefined"
      :tabs="overviewsTabs"
      no-scrollable
      content-padding
    >
      <template #headerRight>
        <TicketBulkEditButton
          :checked-ticket-ids="checkedTicketIds"
          :total-count="currentOverviewCount"
          @open-flyout="openBulkEditFlyout"
        />
      </template>
      <TicketList
        v-if="currentOverview"
        class="px-4 pb-4"
        :overview-id="currentOverview.id"
        :overview-name="currentOverview.name"
        :headers="currentOverview.viewColumnsRaw"
        :order-by="currentOverview.orderBy"
        :order-direction="currentOverview.orderDirection"
        :group-by="currentOverview.groupBy || undefined"
        :overview-count="currentOverviewCount"
      />
      <CommonEmptyMessage
        v-else
        class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
        :title="$t('No overviews')"
        :text="
          $t(
            'Currently, no overviews are assigned to your roles. Please contact your administrator.',
          )
        "
        icon="exclamation-triangle"
      />
    </LayoutContent>

    <DragAndDropBulkWrapper
      v-if="isDragAndDropActive"
      :cursor-position="cursorPosition"
      :preview-data="dragPreviewData"
      :drop-success-target-entity="dropSuccessTargetEntity"
    />
  </div>
</template>
