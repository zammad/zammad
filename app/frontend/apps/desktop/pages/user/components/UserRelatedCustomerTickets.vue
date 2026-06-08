<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { EnumTicketStateTypeCategory, type User } from '#shared/graphql/types.ts'

import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'

import CustomerTicketList from './UserRelatedCustomerTickets/CustomerTicketList.vue'

interface Props {
  customer: User
  customerOrganizations?: boolean
}

defineProps<Props>()
</script>

<template>
  <div class="flex flex-col gap-3">
    <CustomerTicketList
      v-if="customer.ticketsCount?.open"
      :customer="customer"
      :label="__('Open tickets')"
      :state-type-category="EnumTicketStateTypeCategory.Open"
      :customer-organizations="customerOrganizations"
    />
    <CommonDivider v-if="customer.ticketsCount?.open && customer.ticketsCount?.closed" />
    <CustomerTicketList
      v-if="customer.ticketsCount?.closed"
      :customer="customer"
      :label="__('Closed tickets')"
      :state-type-category="EnumTicketStateTypeCategory.Closed"
      :customer-organizations="customerOrganizations"
    />
  </div>
</template>
