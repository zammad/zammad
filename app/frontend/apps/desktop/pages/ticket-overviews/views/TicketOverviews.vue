<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { until } from '@vueuse/core'
import { computed } from 'vue'

import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import TicketBulkEditButton from '#desktop/components/Ticket/TicketBulkEditButton.vue'
import { useTicketBulkEdit } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'
import TicketList from '#desktop/pages/ticket-overviews/components/TicketList.vue'
import TicketOverviewsEmptyText from '#desktop/pages/ticket-overviews/components/TicketOverviewsEmptyText.vue'
import TicketOverviewsSidebar from '#desktop/pages/ticket-overviews/components/TicketOverviewsSidebar.vue'
import { useTicketOverviews } from '#desktop/pages/ticket-overviews/composables/useTicketOverviews.ts'

interface Props {
  overviewLink: string
}

const props = defineProps<Props>()

defineOptions({
  async beforeRouteEnter(to, _, next) {
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
      return next()
    }

    const nextOverviewLink =
      currentTicketOverviewLink.value || overviews.value[0].link
    setCurrentTicketOverviewLink(nextOverviewLink)

    next({
      name: 'TicketOverview',
      params: { overviewLink: nextOverviewLink },
    })
  },
  beforeRouteUpdate(to, _, next) {
    const {
      currentTicketOverviewLink,
      overviews,
      setCurrentTicketOverviewLink,
    } = useTicketOverviews()

    if (to.params.overviewLink) {
      setCurrentTicketOverviewLink(to.params.overviewLink as string)
      return next()
    }

    const nextOverviewLink =
      currentTicketOverviewLink.value || overviews.value[0].link
    setCurrentTicketOverviewLink(nextOverviewLink)

    next({
      name: 'TicketOverview',
      params: { overviewLink: nextOverviewLink },
    })
  },
})

const { overviewsByLink, hasOverviews, overviewsTicketCountById } =
  useTicketOverviews()

const currentOverview = computed(
  () => overviewsByLink.value[props.overviewLink],
)

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

const { checkedTicketIds, openBulkEditFlyout } = useTicketBulkEdit()
</script>

<template>
  <div class="h-full" :class="{ 'grid grid-cols-[260px_1fr]': hasOverviews }">
    <LayoutSidebar
      v-if="hasOverviews"
      id="ticket-overviews"
      :aria-label="$t('second level navigation sidebar')"
      background-variant="secondary"
      name="overviews"
    >
      <TicketOverviewsSidebar />
    </LayoutSidebar>

    <LayoutContent
      class="relative"
      :breadcrumb-items="currentOverview ? breadcrumbItems : undefined"
      no-scrollable
      content-padding
    >
      <template #headerRight>
        <TicketBulkEditButton
          :checked-ticket-ids="checkedTicketIds"
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
      <TicketOverviewsEmptyText
        v-else
        :title="$t('No Overviews')"
        :text="
          $t(
            'Currently, no overviews are assigned to your roles. Please contact your administrator.',
          )
        "
        icon="exclamation-triangle"
      />
    </LayoutContent>
  </div>
</template>
