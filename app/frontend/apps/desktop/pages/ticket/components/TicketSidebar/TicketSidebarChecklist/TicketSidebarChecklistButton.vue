<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted } from 'vue'

import TicketSidebarButton from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarButton.vue'
import { useTicketChecklist } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/useTicketChecklist.ts'
import {
  type TicketSidebarButtonBadgeDetails,
  TicketSidebarButtonBadgeType,
  type TicketSidebarButtonEmits,
  type TicketSidebarButtonProps,
} from '#desktop/pages/ticket/components/types.ts'

defineProps<TicketSidebarButtonProps>()

const emit = defineEmits<TicketSidebarButtonEmits>()

const { incompleteItemCount } = useTicketChecklist()

const badge = computed<TicketSidebarButtonBadgeDetails | undefined>(() => {
  const label = __('Incomplete checklist items')

  if (!incompleteItemCount.value) return

  return {
    type: TicketSidebarButtonBadgeType.Info,
    value: incompleteItemCount.value,
    label,
  }
})

// TODO: Check if it's correct not to have any condition for showing the sidebar.
onMounted(() => {
  emit('show')
})
</script>

<template>
  <TicketSidebarButton
    :key="sidebar"
    :name="sidebar"
    :label="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :selected="selected"
    :badge="badge"
    @click="emit('show')"
  />
</template>
