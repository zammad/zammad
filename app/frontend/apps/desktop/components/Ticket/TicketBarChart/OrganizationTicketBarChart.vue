<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import CommonBarChart from '#desktop/components/CommonCharts/CommonBarChart/CommonBarChart.vue'
import { useTicketsStatsMonthlyByOrganizationQuery } from '#desktop/entities/ticket/graphql/queries/ticketsStatsMonthlyByOrganization.api.ts'

import { useTicketStatsChart } from './useTicketStatsChart.ts'

const props = defineProps<{
  organizationId: string
}>()

const ticketsStatsQuery = new QueryHandler(
  useTicketsStatsMonthlyByOrganizationQuery(() => ({
    organizationId: props.organizationId,
  })),
)

const ticketsStatsResult = ticketsStatsQuery.result()

const stats = computed(() => ticketsStatsResult.value?.ticketsStatsMonthlyByOrganization)

const { option } = useTicketStatsChart(stats)

const refetchData = () => ticketsStatsQuery.refetch()

defineExpose({
  refetchData,
})
</script>

<template>
  <CommonBarChart class="h-72!" :option="option" />
</template>
