<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import { usePagination } from '#shared/composables/usePagination.ts'
import { EnumTicketStateTypeCategory, type User } from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import { useTicketsByCustomerQuery } from '#desktop/entities/ticket/graphql/queries/ticketsByCustomer.api.ts'

import CustomerTicketListSkeleton from './skeleton/CustomerTicketListSkeleton.vue'

export interface Props {
  customer: User
  label: string
  stateTypeCategory: EnumTicketStateTypeCategory
  customerOrganizations?: boolean
}

const props = defineProps<Props>()

const customerTicketsQuery = new QueryHandler(
  useTicketsByCustomerQuery(() => ({
    customerId: props.customer.id,
    customerOrganizations: props.customerOrganizations,
    stateTypeCategory: props.stateTypeCategory,
    pageSize: 5,
  })),
)

const customerTicketsResult = customerTicketsQuery.result()

const loading = customerTicketsQuery.loadingWithoutCachedResult()

const customerTickets = computed(() =>
  normalizeEdges(customerTicketsResult.value?.ticketsByCustomer),
)

const pagination = usePagination(customerTicketsQuery, 'ticketsByCustomer', 100)

useOnEmitter(`customer-ticket-list-refetch:${props.customer.id}`, () => {
  customerTicketsQuery.refetch()
})

const searchQuery = computed(() => {
  switch (props.stateTypeCategory) {
    case EnumTicketStateTypeCategory.Open:
      if (props.customerOrganizations)
        return props.customer.ticketsCount?.organizationOpenSearchQuery
      return props.customer.ticketsCount?.openSearchQuery
    case EnumTicketStateTypeCategory.Closed:
      if (props.customerOrganizations)
        return props.customer.ticketsCount?.organizationClosedSearchQuery
      return props.customer.ticketsCount?.closedSearchQuery
    default:
      return undefined
  }
})

const router = useRouter()

const goToTicketSearch = () => {
  if (!searchQuery.value) return

  router.push(`/search/${searchQuery.value}`)
}
</script>

<template>
  <CustomerTicketListSkeleton :loading="loading">
    <CommonSimpleEntityList
      :id="`customer-ticket-list-${customerOrganizations ? 'orgs-' : ''}${stateTypeCategory}`"
      :type="EntityType.Ticket"
      :label="label"
      :entity="customerTickets"
      has-popover
      no-collapse
    >
      <template #trailing="{ entities, totalCount }">
        <div v-if="totalCount" class="flex items-center justify-end gap-2.5">
          <CommonShowMoreButton
            :entities="entities"
            :total-count="totalCount"
            @click="pagination.fetchNextPage"
          />
          <CommonButton
            v-if="totalCount > 5"
            variant="secondary"
            size="small"
            @click="goToTicketSearch"
          >
            {{ $t('Search all') }}
          </CommonButton>
        </div>
      </template>
    </CommonSimpleEntityList>
  </CustomerTicketListSkeleton>
</template>
