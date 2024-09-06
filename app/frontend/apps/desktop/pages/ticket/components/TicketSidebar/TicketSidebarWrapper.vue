<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import TicketSidebarButton from './TicketSidebarButton.vue'

import type { TicketSidebarWrapperProps } from '../../types/sidebar.ts'

defineProps<TicketSidebarWrapperProps>()

defineEmits<{
  click: [string]
}>()
</script>

<template>
  <div>
    <TicketSidebarButton
      :key="sidebar"
      :name="sidebar"
      :label="sidebarPlugin.title"
      :icon="sidebarPlugin.icon"
      :badge="badge"
      :selected="selected"
      :update-indicator="updateIndicator"
      @click="$emit('click', $event)"
    />
    <Teleport v-if="selected" to="#ticketSidebar">
      <slot />
    </Teleport>
  </div>
</template>
