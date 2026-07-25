// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import TicketSidebarSnipeit from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/TicketSidebarSnipeit.vue'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Snipe-IT'),
  component: TicketSidebarSnipeit,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketDetailView, TicketSidebarScreenType.TicketCreate],
  icon: 'snipeit-logo', // icon does not exist underlying cmp will use it as a base to get light and dark icon name
  order: 6100,
  available: () => useApplicationStore().config.snipeit_integration,
}
