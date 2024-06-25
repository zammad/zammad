<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { watch, computed, toRef } from 'vue'

import { useUserDetail } from '#shared/entities/user/composables/useUserDetail.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { useTicketSidebar } from '../../composables/useTicketSidebar.ts'
import {
  TicketSidebarScreenType,
  type TicketSidebarContext,
  TicketSidebarButtonBadgeType,
  type TicketSidebarButtonBadgeDetails,
} from '../types.ts'

import TicketSidebarButton from './TicketSidebarButton.vue'

import type { TicketSidebarPlugin } from './plugins/types.ts'

interface Props {
  sidebar: string
  sidebarPlugin: TicketSidebarPlugin
  context: TicketSidebarContext
  selected: boolean
}

const application = useApplicationStore()

const props = defineProps<Props>()

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

const { showSidebar, hideSidebar } = useTicketSidebar(toRef(props, 'context'))

watch(customer, (newValue) => {
  if (!newValue) {
    hideSidebar(props.sidebar)
    return
  }

  showSidebar(props.sidebar)
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
