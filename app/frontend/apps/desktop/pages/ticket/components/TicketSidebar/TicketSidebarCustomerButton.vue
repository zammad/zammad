<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watch, computed } from 'vue'

import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import {
  TicketSidebarScreenType,
  TicketSidebarButtonBadgeType,
  type TicketSidebarButtonBadgeDetails,
  type TicketSidebarButtonProps,
  type TicketSidebarButtonEmits,
} from '../types.ts'

import TicketSidebarButton from './TicketSidebarButton.vue'

const application = useApplicationStore()

const props = defineProps<TicketSidebarButtonProps>()

const emit = defineEmits<TicketSidebarButtonEmits>()

const customerId = computed(() => Number(props.context.formValues.customer_id))

const { user: customer } = useUserDetail(customerId, undefined, 'cache-first')

const calculateBadgeType = (value: number): TicketSidebarButtonBadgeType => {
  if (!application.config.ui_sidebar_open_ticket_indicator_colored)
    return TicketSidebarButtonBadgeType.Info

  if (props.context.screenType === TicketSidebarScreenType.TicketDetailView)
    value -= 1

  switch (value) {
    case 0:
      return TicketSidebarButtonBadgeType.Info
    case 1:
      return TicketSidebarButtonBadgeType.Warning
    case 2:
    default:
      return TicketSidebarButtonBadgeType.Danger
  }
}

const badge = computed<TicketSidebarButtonBadgeDetails | undefined>(() => {
  const label = __('Open tickets')
  const value = customer.value?.ticketsCount?.open

  if (!value) return

  const type = calculateBadgeType(Number(value))

  return { label, value, type }
})

watch(customer, (newValue) => {
  if (!newValue) {
    emit('hide')
    return
  }

  emit('show')
})
</script>

<template>
  <TicketSidebarButton
    :key="sidebar"
    :name="sidebar"
    :label="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :badge="badge"
    :selected="selected"
  />
</template>
