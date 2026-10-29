<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { EnumObjectManagerObjects, type Organization, type User } from '#shared/graphql/types.ts'
import { SYSTEM_USER_ID } from '#shared/utils/constants.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import CommonTicketEscalationIndicator from '#desktop/components/CommonTicketEscalationIndicator/CommonTicketEscalationIndicator.vue'
import CommonTicketStateIndicator from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicator.vue'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'
import UserInfo from '#desktop/components/User/UserInfo.vue'

import type { TicketPopoverTicket } from './types.ts'

interface Props {
  ticket: TicketPopoverTicket
}

const props = defineProps<Props>()

const { attributes } = useObjectAttributes(EnumObjectManagerObjects.Ticket)

const objectAttributes = computed(() =>
  attributes.value.filter((attribute) =>
    ['number', 'created_at', 'group_id', 'priority_id'].includes(attribute.name),
  ),
)

const isOwnerSystemUser = computed(() => props.ticket.owner.id === SYSTEM_USER_ID)
</script>

<template>
  <CommonLabel class="block!" size="large">
    {{ ticket.title }}
  </CommonLabel>

  <div class="flex items-center gap-2">
    <CommonTicketEscalationIndicator class="h-7" :ticket="ticket as TicketById" />

    <CommonTicketStateIndicator
      class="h-7"
      :color-code="ticket.stateColorCode"
      :label="ticket.state.name"
    />
  </div>

  <CommonSectionCollapse
    v-if="!isOwnerSystemUser"
    id="ticket-owner-popover"
    :title="__('Owner')"
    no-collapse
  >
    <UserInfo :user="ticket.owner as User" size="small" dense />
  </CommonSectionCollapse>

  <CommonSectionCollapse id="ticket-customer-popover" :title="__('Customer')" no-collapse>
    <UserInfo :user="ticket.customer as User" size="small" dense />
  </CommonSectionCollapse>

  <CommonSectionCollapse
    v-if="ticket.organization"
    id="ticket-organization-popover"
    :title="__('Organization')"
    no-collapse
  >
    <OrganizationInfo size="small" dense :organization="ticket.organization as Organization" />
  </CommonSectionCollapse>

  <ObjectAttributes
    class="border-t border-neutral-100 pt-2.5 dark:border-gray-900"
    :object="ticket"
    :attributes="objectAttributes"
    include-static
  />
</template>
