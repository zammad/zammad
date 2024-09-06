<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

// eslint-disable-next-line @typescript-eslint/no-empty-object-type
interface Props extends TicketSidebarContentProps {}

defineProps<Props>()
</script>

<template>
  <TicketSidebarContent :title="sidebarPlugin.title" :icon="sidebarPlugin.icon">
    <div id="ticketEditAttributeForm"></div>
  </TicketSidebarContent>
</template>
