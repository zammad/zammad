<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { useChangeCustomerMenuItem } from '#desktop/pages/ticket/components/TicketSidebar/TicketDetailView/actions/TicketChangeCustomer/useChangeCustomerMenuItem.ts'
import TicketAccountedTime from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketAccountedTime.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  type TicketSidebarContentProps,
  TicketSidebarScreenType,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

import TicketSubscribers from './TicketSidebarInformationContent/TicketSubscribers.vue'
import TicketTags from './TicketSidebarInformationContent/TicketTags.vue'

const props = defineProps<TicketSidebarContentProps>()

const { ticket } = useTicketInformation()

const { isTicketAgent, isTicketEditable } = useTicketView(ticket)

const actions = computed<MenuItem[]>(() => {
  const availableActions: MenuItem[] = []

  // :TODO find a better way to split this up maybe on plugin level
  // :TODO find a way to provide the ticket via prop
  if (props.context.screenType === TicketSidebarScreenType.TicketDetailView) {
    const { customerChangeMenuItem } = useChangeCustomerMenuItem()
    availableActions.push(customerChangeMenuItem)
  }

  return availableActions // ADD the rest available menu actions
})
</script>

<template>
  <TicketSidebarContent
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :actions="actions"
  >
    <CommonSectionCollapse id="ticket-attributes" :title="__('Attributes')">
      <div
        id="ticketEditAttributeForm"
        data-test-id="ticket-edit-attribute-form"
      />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="isTicketAgent"
      id="ticket-tags"
      :title="__('Tags')"
    >
      <TicketTags :ticket="ticket" :is-ticket-editable="isTicketEditable" />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="ticket?.timeUnit && isTicketAgent"
      id="ticket-time-accounting"
      :title="__('Accounted Time')"
    >
      <TicketAccountedTime :ticket="ticket!" />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="isTicketAgent"
      id="ticket-subscribers"
      :title="__('Subscribers')"
    >
      <TicketSubscribers :ticket="ticket" />
    </CommonSectionCollapse>
  </TicketSidebarContent>
</template>
