<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watch, computed } from 'vue'

import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { usePersistentStates } from '#desktop/pages/ticket/composables/usePersistentStates.ts'
import {
  type TicketSidebarProps,
  type TicketSidebarEmits,
  TicketSidebarButtonBadgeType,
  TicketSidebarScreenType,
  type TicketSidebarButtonBadgeDetails,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

import TicketSidebarCustomerContent from './TicketSidebarCustomerContent.vue'

const props = defineProps<TicketSidebarProps>()

const { persistentStates } = usePersistentStates()

const emit = defineEmits<TicketSidebarEmits>()

// TODO: only for now, implement correct situation for create/detail view.
const customerId = computed(() =>
  props.context.formValues?.customer_id
    ? convertToGraphQLId('User', props.context.formValues.customer_id as string)
    : undefined,
)

const {
  user: customer,
  secondaryOrganizations,
  objectAttributes,
  fetchMoreSecondaryOrganizations,
} = useUserDetail(customerId)

const calculateBadgeType = (value: number) => {
  // If the sidebar is open in the ticket detail view,
  //   we need to subtract 1 from the value to account for the ticket itself.
  if (props.context.screenType === TicketSidebarScreenType.TicketDetailView) value -= 1

  return value > 1 ? TicketSidebarButtonBadgeType.Alarming : TicketSidebarButtonBadgeType.Default
}

const badge = computed<TicketSidebarButtonBadgeDetails | undefined>(() => {
  const label = __('Open tickets')
  const value = customer.value?.ticketsCount?.open

  if (!value) return

  const type = calculateBadgeType(Number(value))

  return { label, value, type }
})

// When customerId is present, show the sidebar (for unknown customers the check is
// already inside the available sidebar plugin).
watch(customerId, (newValue) => {
  if (!newValue) {
    emit('hide')
    return
  }

  emit('show')
})

// On initial setup we show the sidebar if customerId is present.
if (customerId.value) emit('show')
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :selected="selected"
    :badge="badge"
  >
    <TicketSidebarCustomerContent
      v-if="customer"
      v-model="persistentStates"
      :context="context"
      :sidebar-plugin="sidebarPlugin"
      :customer="customer"
      :secondary-organizations="secondaryOrganizations"
      :object-attributes="objectAttributes"
      @load-more-secondary-organizations="fetchMoreSecondaryOrganizations"
    />
  </TicketSidebarWrapper>
</template>
