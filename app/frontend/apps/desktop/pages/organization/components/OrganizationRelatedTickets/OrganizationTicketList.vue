<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import { usePagination } from '#shared/composables/usePagination.ts'
import { EnumTicketStateTypeCategory, type Organization } from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonShowMoreButton from '#desktop/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import { useTicketsByOrganizationQuery } from '#desktop/entities/ticket/graphql/queries/ticketsByOrganization.api.ts'

import OrganizationTicketListSkeleton from './skeleton/OrganizationTicketListSkeleton.vue'

export interface Props {
  organization: Organization
  label: string
  stateTypeCategory: EnumTicketStateTypeCategory
}

const props = defineProps<Props>()

const organizationTicketsQuery = new QueryHandler(
  useTicketsByOrganizationQuery(() => ({
    organizationId: props.organization.id,
    stateTypeCategory: props.stateTypeCategory,
    pageSize: 5,
  })),
)

const organizationTicketsResult = organizationTicketsQuery.result()

const loading = organizationTicketsQuery.loadingWithoutCachedResult()

const organizationTickets = computed(() =>
  normalizeEdges(organizationTicketsResult.value?.ticketsByOrganization),
)

const pagination = usePagination(organizationTicketsQuery, 'ticketsByOrganization', 100)

useOnEmitter(`organization-ticket-list-refetch:${props.organization.id}`, () => {
  organizationTicketsQuery.refetch()
})

const searchQuery = computed(() => {
  switch (props.stateTypeCategory) {
    case EnumTicketStateTypeCategory.Open:
      return props.organization.ticketsCount?.openSearchQuery
    case EnumTicketStateTypeCategory.Closed:
      return props.organization.ticketsCount?.closedSearchQuery
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
  <OrganizationTicketListSkeleton :loading="loading">
    <CommonSimpleEntityList
      :id="`organization-ticket-list-${stateTypeCategory}`"
      :type="EntityType.Ticket"
      :label="label"
      :entity="organizationTickets"
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
  </OrganizationTicketListSkeleton>
</template>
