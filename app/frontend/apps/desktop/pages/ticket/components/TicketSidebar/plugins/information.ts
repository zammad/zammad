// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarInformation from '../TicketSidebarInformation/TicketSidebarInformation.vue'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Ticket'),
  component: TicketSidebarInformation,
  permissions: ['ticket.agent', 'ticket.customer'],
  screens: [TicketSidebarScreenType.TicketDetailView],
  icon: 'chat-left-text',
  order: 100,
}
