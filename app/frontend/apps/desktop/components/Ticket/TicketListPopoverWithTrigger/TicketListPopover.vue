<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { TicketsByFilterQueryVariables } from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'
import { useTicketsByFilterQuery } from '#desktop/entities/ticket/graphql/queries/ticketsByFilter.api.ts'

import TicketListPopoverSkeleton from './skeleton/TicketListPopoverSkeleton.vue'

interface Props {
  filters: TicketsByFilterQueryVariables
  title: string
  searchLink?: string
  noResults?: boolean
}

const props = defineProps<Props>()

const ticketsByFilterQuery = new QueryHandler(
  useTicketsByFilterQuery(
    () => props.filters,
    () => ({ enabled: !props.noResults, fetchPolicy: 'cache-and-network' }),
  ),
)

const ticketsByFilterResult = ticketsByFilterQuery.result()
const loading = ticketsByFilterQuery.loading()
const tickets = computed(() => normalizeEdges(ticketsByFilterResult.value?.ticketsByFilter))

const { debouncedLoading } = useDebouncedLoading({
  isLoading: loading,
})

const router = useRouter()

const goToTicketSearch = () => {
  if (!props.searchLink) return

  router.push(props.searchLink)
}
</script>

<template>
  <section ref="popover-section" data-type="popover" class="px-3 py-2 flex flex-col">
    <CommonSectionCollapse id="tickets-popover-title" :title="title" no-collapse>
      <TicketListPopoverSkeleton v-if="debouncedLoading && !tickets.array.length" />
      <template v-else>
        <CommonLabel v-if="noResults || !tickets.totalCount">
          {{ $t('No results found') }}
        </CommonLabel>
        <div v-else class="flex flex-col gap-2 max-w-90">
          <CommonTicketLabel
            v-for="ticket in tickets.array"
            :key="ticket.id"
            class="h-9"
            no-wrap
            :ticket="ticket as TicketById"
          />
          <CommonButton
            v-if="searchLink && tickets.array.length < tickets.totalCount"
            class="mb-1"
            variant="secondary"
            size="small"
            @click="goToTicketSearch"
          >
            {{ $t('Show %s more', tickets.totalCount - tickets.array.length) }}
          </CommonButton>
        </div>
      </template>
    </CommonSectionCollapse>
  </section>
</template>
