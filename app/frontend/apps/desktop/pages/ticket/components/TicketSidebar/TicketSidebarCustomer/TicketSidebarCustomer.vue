<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watch, computed } from 'vue'

import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { isSystemUserId } from '#shared/entities/user/utils/isSystemUser.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { usePersistentStates } from '#desktop/pages/ticket/composables/usePersistentStates.ts'
import {
  type TicketSidebarProps,
  type TicketSidebarEmits,
  TicketSidebarButtonBadgeType,
  TicketSidebarScreenType,
  type TicketSidebarButtonBadgeDetails,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'
import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

import TicketSidebarCustomerContent from './TicketSidebarCustomerContent.vue'
import { useChangeCustomerMenuItem } from './useChangeCustomerMenuItem.ts'

const props = defineProps<TicketSidebarProps>()

const { persistentStates } = usePersistentStates()

const emit = defineEmits<TicketSidebarEmits>()

// TODO: only for now, implement correct situation for create/detail view.
const customerId = computed(() =>
  props.context.formValues?.customer_id
    ? convertToGraphQLId('User', props.context.formValues.customer_id as string)
    : undefined,
)

const isSystemCustomer = computed(() => isSystemUserId(customerId.value))

const {
  user: customer,
  secondaryOrganizations,
  objectAttributes,
  fetchMoreSecondaryOrganizations,
} = useUserDetail(computed(() => (isSystemCustomer.value ? undefined : customerId.value)))

const changeCustomerMenuItem = useChangeCustomerMenuItem(props.context)

const noCustomerActions = [changeCustomerMenuItem]

const calculateBadgeType = (value: number) => {
  // If the sidebar is open in the ticket detail view,
  //   we need to subtract 1 from the value to account for the ticket itself.
  if (props.context.screenType === TicketSidebarScreenType.TicketDetailView) value -= 1

  return value > 1 ? TicketSidebarButtonBadgeType.Alarming : TicketSidebarButtonBadgeType.Default
}

const badge = computed<TicketSidebarButtonBadgeDetails | undefined>(() => {
  if (isSystemCustomer.value) return

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
    <TicketSidebarContent
      v-if="isSystemCustomer"
      v-model="persistentStates.scrollPosition"
      :title="sidebarPlugin.title"
      :icon="sidebarPlugin.icon"
      :actions="noCustomerActions"
    >
      <CommonLabel size="small">
        {{ $t('No customer assigned yet.') }}
      </CommonLabel>
    </TicketSidebarContent>
    <TicketSidebarCustomerContent
      v-else-if="customer"
      v-model="persistentStates"
      :context="context"
      :sidebar-plugin="sidebarPlugin"
      :customer="customer"
      :secondary-organizations="secondaryOrganizations"
      :object-attributes="objectAttributes"
      :change-customer-menu-item="changeCustomerMenuItem"
      @load-more-secondary-organizations="fetchMoreSecondaryOrganizations"
    />
  </TicketSidebarWrapper>
</template>
