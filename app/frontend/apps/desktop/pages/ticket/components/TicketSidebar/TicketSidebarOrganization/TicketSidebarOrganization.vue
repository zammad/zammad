<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watch, computed } from 'vue'

import { useOrganizationDetail } from '#shared/entities/organization/composables/useOrganizationDetail.ts'
import { useUserQuery } from '#shared/entities/user/graphql/queries/user.api.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import type {
  TicketSidebarProps,
  TicketSidebarEmits,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

import TicketSidebarOrganizationContent from './TicketSidebarOrganizationContent.vue'

const props = defineProps<TicketSidebarProps>()

const emit = defineEmits<TicketSidebarEmits>()

const customerId = computed(() => Number(props.context.formValues.customer_id))

// Query is using cache first so it should normally not trigger any additional request, because the customer sidebar
// is alreaddy doing the same query.
const userQuery = new QueryHandler(
  useUserQuery(
    () => ({
      userInternalId: customerId.value,
      secondaryOrganizationsCount: 3,
    }),
    () => ({ enabled: Boolean(customerId.value), fetchPolicy: 'cache-first' }),
  ),
)

const userResult = userQuery.result()
const customer = computed(() => userResult.value?.user)

watch(customer, (newValue) => {
  if (!newValue?.organization) {
    emit('hide')
    return
  }
  emit('show')
})

const organizationInternalId = computed(() => {
  if (props.context.formValues?.organization_id)
    return Number(props.context.formValues?.organization_id)

  return customer.value?.organization?.internalId
})

const { organization, organizationMembers, objectAttributes, loadAllMembers } =
  useOrganizationDetail(organizationInternalId)
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :selected="selected"
  >
    <TicketSidebarOrganizationContent
      v-if="organization"
      :context="context"
      :sidebar-plugin="sidebarPlugin"
      :organization="organization"
      :organization-members="organizationMembers"
      :object-attributes="objectAttributes"
      @load-more-members="loadAllMembers"
    />
  </TicketSidebarWrapper>
</template>
