<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

import TicketTags from './TicketSidebarInformationContent/TicketTags.vue'

defineProps<TicketSidebarContentProps>()

const { ticket } = useTicketInformation()

const { isTicketAgent, isTicketEditable } = useTicketView(ticket)
</script>

<template>
  <TicketSidebarContent :title="sidebarPlugin.title" :icon="sidebarPlugin.icon">
    <CommonSectionCollapse id="ticket-attributes" :title="__('Attributes')">
      <div id="ticketEditAttributeForm"></div>
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="isTicketAgent"
      id="ticket-tags"
      :title="__('Tags')"
    >
      <TicketTags :ticket="ticket" :is-ticket-editable="isTicketEditable" />
    </CommonSectionCollapse>
  </TicketSidebarContent>
</template>
