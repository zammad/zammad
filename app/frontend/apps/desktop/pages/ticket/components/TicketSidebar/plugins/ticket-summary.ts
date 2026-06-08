// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import TicketSidebarSummary from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/TicketSidebarSummary.vue'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('AI summary'),
  component: TicketSidebarSummary,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketDetailView],
  views: ['agent'],
  icon: 'smart-assist',
  order: 6500,
  available: () => {
    const { config } = useApplicationStore()
    return config.ai_assistance_ticket_summary
  },
}
