<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onMounted } from 'vue'

import TicketSidebarButton from './TicketSidebarButton.vue'

import type {
  TicketSidebarButtonProps,
  TicketSidebarButtonEmits,
} from '../types.ts'

defineProps<TicketSidebarButtonProps>()

const emit = defineEmits<TicketSidebarButtonEmits>()

// TODO: Check if it's correct not to have any condition for showing the sidebar.
onMounted(() => {
  console.debug('onMounted')
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
  />
</template>
