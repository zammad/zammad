// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import TicketSidebarIdoit from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/TicketSidebarIdoit.vue'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('i-doit'),
  component: TicketSidebarIdoit,
  permissions: ['ticket.agent'],
  screens: [
    TicketSidebarScreenType.TicketDetailView,
    TicketSidebarScreenType.TicketCreate,
  ],
  icon: 'i-doit-logo', // icon does not exist underlying cmp will use it as a base to get light and dark icon name
  order: 6000,
  available: () => useApplicationStore().config.idoit_integration,
}
