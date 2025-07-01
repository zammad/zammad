<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { useTodaysTicketsQuery } from '../graphql/queries/todaysTickets.api.ts'

import CommonContentPanel from '#desktop/components/CommonContentPanel/CommonContentPanel.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import CommonTicketStateIndicator from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import CommonTicketPriorityIndicator from '#desktop/components/CommonTicketPriorityIndicator/CommonTicketPriorityIndicator.vue'

const { result, loading, error, refetch } = useTodaysTicketsQuery({
  fetchPolicy: 'cache-and-network',
  errorPolicy: 'all',
})

const todaysTickets = computed(() => result.value?.todaysTickets || [])
const todaysTicketsCount = computed(() => todaysTickets.value.length)

let refreshInterval: NodeJS.Timeout | undefined

onMounted(() => {
  refreshInterval = setInterval(() => {
    if (refetch) refetch()
  }, 30000)
})

onUnmounted(() => {
  if (refreshInterval) clearInterval(refreshInterval)
})

const refetchTickets = () => {
  if (refetch) refetch()
}

const extractTicketId = (graphqlId: string) => {
  return graphqlId.split('/').pop()
}
</script>

<template>
  <CommonContentPanel>
    <div class="flex items-center justify-between mb-4">
      <CommonLabel size="large" class="text-gray-100 dark:text-neutral-400">
        {{ $t("Today's Tickets") }}
      </CommonLabel>
      <div class="flex items-center gap-3">
        <button @click="refetchTickets" :disabled="loading" :title="$t('Refresh tickets')"
          class="p-2 rounded-md hover:bg-neutral-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors dark:hover:bg-neutral-800">
          <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" :class="{ 'animate-spin': loading }" fill="none"
            stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>

        <div class="flex items-center gap-2">
          <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
          <CommonLabel size="small" class="text-stone-200 dark:text-neutral-500">
            {{ $t('Auto-refresh every %s seconds', '30') }}
          </CommonLabel>
        </div>
      </div>
    </div>

    <div v-if="loading" class="flex flex-col items-center justify-center py-8">
      <CommonLoader loading />
      <CommonLabel class="mt-2 text-stone-200 dark:text-neutral-500">
        {{ $t('Loading tickets...') }}
      </CommonLabel>
    </div>

    <div v-else-if="error" class="text-center py-8">
      <CommonIcon name="x-lg" class="text-red-500 mb-2" size="base" />
      <CommonLabel class="block mb-2 text-red-600">
        {{ $t('Failed to load tickets') }}
      </CommonLabel>
      <CommonLabel size="small" class="block mb-3 text-stone-200 dark:text-neutral-500">
        {{ error.message }}
      </CommonLabel>
      <CommonButton @click="refetchTickets" variant="secondary" size="small">
        {{ $t('Try again') }}
      </CommonButton>
    </div>

    <div v-else class="space-y-4">
      <div class="rounded-lg bg-blue-50 p-4 dark:bg-blue-900/20">
        <div class="text-2xl font-bold text-blue-900 dark:text-blue-100">
          {{ todaysTicketsCount }}
        </div>
        <CommonLabel size="small" class="text-blue-700 dark:text-blue-300">
          {{ todaysTicketsCount === 1 ? $t('ticket created today') : $t('tickets created today') }}
        </CommonLabel>
      </div>

      <div v-if="todaysTickets.length > 0" class="space-y-2 max-h-96 overflow-y-auto">
        <CommonLink v-for="ticket in todaysTickets" :key="ticket.id" :link="`/tickets/${extractTicketId(ticket.id)}`"
          internal
          class="block rounded-lg border border-neutral-100 p-3 hover:bg-blue-50 dark:border-gray-900 dark:hover:bg-blue-900/10">
          <div class="space-y-2">
            <div class="flex items-start justify-between">
              <div class="flex-1 min-w-0">
                <CommonLabel class="font-medium text-black dark:text-white">
                  #{{ ticket.number }} - {{ ticket.title }}
                </CommonLabel>
                <CommonLabel tag="p" class="text-gray-100 dark:text-neutral-400 mt-0.5" size="small">
                  {{ ticket.customer?.fullname || ticket.customer?.email || $t('Unknown Customer') }}
                </CommonLabel>
              </div>

              <div class="flex items-center gap-1.5 shrink-0 ml-3">
                <CommonTicketStateIndicator :color-code="ticket.stateColorCode" :label="ticket.state?.name" />
                <CommonTicketPriorityIndicator :priority="ticket.priority" />
              </div>
            </div>

            <div class="flex items-center justify-between">
              <CommonBadge variant="tertiary" class="uppercase">
                <CommonDateTime :date-time="ticket.createdAt" absolute-format="date" class="ms-1">
                  <template #prefix>
                    {{ $t('Created') }}
                  </template>
                </CommonDateTime>
              </CommonBadge>

              <CommonLabel size="small" class="text-stone-200 dark:text-neutral-500">
                {{ ticket.group?.name || $t('Unassigned') }} | {{ ticket.owner?.fullname || $t('Unassigned') }}
              </CommonLabel>
            </div>
          </div>
        </CommonLink>
      </div>

      <div v-else class="text-center py-8">
        <CommonIcon name="document" class="text-stone-200 dark:text-neutral-500 mb-3" size="large" />
        <CommonLabel class="block text-stone-200 dark:text-neutral-500">
          {{ $t('No tickets created today') }}
        </CommonLabel>
        <CommonLabel size="small" class="text-stone-200 dark:text-neutral-500">
          {{ $t('All tickets created today will appear here') }}
        </CommonLabel>
      </div>
    </div>
  </CommonContentPanel>
</template>