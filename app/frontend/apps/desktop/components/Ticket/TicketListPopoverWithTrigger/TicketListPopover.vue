<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import type { TicketsByCustomerQueryVariables } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import { useTicketsByCustomerQuery } from '#desktop/entities/ticket/graphql/queries/ticketsByCustomer.api.ts'

import TicketListPopoverSkeleton from './skeleton/TicketListPopoverSkeleton.vue'

interface Props {
  filters: TicketsByCustomerQueryVariables
  title: string
  searchLink?: string
  noResults?: boolean
}

const props = defineProps<Props>()

const ticketsByFilterQuery = new QueryHandler(
  useTicketsByCustomerQuery(
    () => props.filters,
    () => ({ enabled: !props.noResults, fetchPolicy: 'cache-and-network' }),
  ),
)

const ticketsByCustomerResult = ticketsByFilterQuery.result()
const loading = ticketsByFilterQuery.loadingWithoutCachedResult()
const tickets = computed(() => normalizeEdges(ticketsByCustomerResult.value?.ticketsByCustomer))

const router = useRouter()

const goToUserProfile = () => {
  if (!props.filters.customerId) return

  router.push(`/users/${getIdFromGraphQLId(props.filters.customerId)}`)
}
</script>

<template>
  <section ref="popover-section" data-type="popover" class="flex flex-col px-3 py-2">
    <TicketListPopoverSkeleton :loading="loading">
      <CommonSimpleEntityList
        id="ticket-list-popover"
        :type="EntityType.Ticket"
        :label="title"
        :entity="tickets"
        no-collapse
        @load-more="goToUserProfile"
      />
    </TicketListPopoverSkeleton>
  </section>
</template>
