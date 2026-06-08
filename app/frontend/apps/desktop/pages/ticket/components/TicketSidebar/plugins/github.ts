// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import TicketSidebarGitHub from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/TicketSidebarGitHub/TicketSidebarGitHub.vue'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('GitHub'),
  component: TicketSidebarGitHub,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketDetailView, TicketSidebarScreenType.TicketCreate],
  views: ['agent'],
  icon: 'github',
  order: 4000,
  available: () => useApplicationStore().config.github_integration,
}
