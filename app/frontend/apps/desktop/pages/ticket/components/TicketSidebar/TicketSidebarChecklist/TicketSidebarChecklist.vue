<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted } from 'vue'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  type TicketSidebarProps,
  type TicketSidebarEmits,
  TicketSidebarButtonBadgeType,
  type TicketSidebarButtonBadgeDetails,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

import TicketSidebarChecklistContent from './TicketSidebarChecklistContent.vue'

defineProps<TicketSidebarProps>()

const emit = defineEmits<TicketSidebarEmits>()

const { ticket } = useTicketInformation()

const incompleteChecklistItemsCount = computed(
  () => ticket.value?.checklist?.incomplete,
)

const badge = computed<TicketSidebarButtonBadgeDetails | undefined>(() => {
  const label = __('Incomplete checklist items')

  if (!incompleteChecklistItemsCount.value) return

  return {
    type: TicketSidebarButtonBadgeType.Info,
    value: incompleteChecklistItemsCount.value,
    label,
  }
})

onMounted(() => {
  emit('show')
})
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :selected="selected"
    :badge="badge"
  >
    <TicketSidebarChecklistContent
      :context="context"
      :sidebar-plugin="sidebarPlugin"
    />
  </TicketSidebarWrapper>
</template>
