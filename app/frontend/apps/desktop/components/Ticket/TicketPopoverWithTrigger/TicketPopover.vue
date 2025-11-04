<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import {
  EnumObjectManagerObjects,
  type Organization,
  type Ticket,
  type User,
} from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { SYSTEM_USER_ID } from '#shared/utils/constants.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonTicketEscalationIndicator from '#desktop/components/CommonTicketEscalationIndicator/CommonTicketEscalationIndicator.vue'
import CommonTicketStateIndicator from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'
import UserInfo from '#desktop/components/User/UserInfo.vue'

import { useTicketInfoForPopoverQuery } from './graphql/queries/ticketInfoForPopover.api.ts'
import TicketPopoverSkeleton from './skeleton/TicketPopoverSkeleton.vue'

interface Props {
  ticket: Partial<Ticket | TicketById>
}

const props = defineProps<Props>()

const ticketInfoForPopoverQuery = new QueryHandler(
  useTicketInfoForPopoverQuery(
    () => ({ ticketId: props.ticket.id! }),
    () => ({ enabled: !!props.ticket.id, fetchPolicy: 'cache-and-network' }),
  ),
)

const ticketResult = ticketInfoForPopoverQuery.result()

const ticketData = computed(() => ticketResult.value?.ticket)

const { debouncedLoading } = useDebouncedLoading({
  isLoading: ticketInfoForPopoverQuery.loading(),
})

const { attributes } = useObjectAttributes(EnumObjectManagerObjects.Ticket)

const objectAttributes = computed(() =>
  attributes.value.filter((attribute) =>
    ['number', 'created_at', 'group_id', 'priority_id'].includes(attribute.name),
  ),
)

const isOwnerSystemUser = computed(() => {
  if (!ticketData.value) return false

  const { id } = ticketData.value.owner

  return id === SYSTEM_USER_ID
})
</script>

<template>
  <section ref="popover-section" data-type="popover" class="space-y-2 p-3 max-w-prose">
    <TicketPopoverSkeleton v-if="debouncedLoading && !ticketData" />
    <template v-else-if="ticketData">
      <CommonLabel class="block!" size="large">
        {{ ticketData.title }}
      </CommonLabel>

      <div class="flex items-center gap-2">
        <CommonTicketEscalationIndicator class="h-7" :ticket="ticketData as TicketById" />

        <CommonTicketStateIndicator
          class="h-7"
          :color-code="ticketData.stateColorCode"
          :label="ticketData.state.name"
        />
      </div>

      <CommonSectionCollapse
        v-if="!isOwnerSystemUser"
        id="ticket-owner-popover"
        :title="__('Owner')"
        no-collapse
      >
        <UserInfo :user="ticketData.owner as User" size="small" dense />
      </CommonSectionCollapse>

      <CommonSectionCollapse id="ticket-customer-popover" :title="__('Customer')" no-collapse>
        <UserInfo :user="ticketData.customer as User" size="small" dense />
      </CommonSectionCollapse>

      <CommonSectionCollapse
        v-if="ticketData.organization"
        id="ticket-organization-popover"
        :title="__('Organization')"
        no-collapse
      >
        <OrganizationInfo
          size="small"
          dense
          :organization="ticketData.organization as Organization"
        />
      </CommonSectionCollapse>

      <ObjectAttributes
        class="border-t border-neutral-100 dark:border-gray-900 pt-2.5"
        :object="ticketData"
        :attributes="objectAttributes"
        include-static
      />
    </template>
  </section>
</template>
