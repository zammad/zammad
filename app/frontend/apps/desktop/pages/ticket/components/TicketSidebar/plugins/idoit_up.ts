// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import TicketSidebarIdoitUp from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoitUp/TicketSidebarIdoitUp.vue'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('i-doit up'),
  component: TicketSidebarIdoitUp,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketDetailView, TicketSidebarScreenType.TicketCreate],
  views: ['agent'],
  icon: 'i-doit-up-logo', // icon does not exist underlying cmp will use it as a base to get light and dark icon name
  order: 6001,
  available: () => useApplicationStore().config.idoit_up_integration,
}
