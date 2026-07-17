// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  TicketSidebarScreenType,
  type TicketSidebarContext,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarParticipants from '../TicketSidebarParticipants/TicketSidebarParticipants.vue'

import type { TicketSidebarPlugin } from './types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

export default <TicketSidebarPlugin>{
  title: __('Participants'),
  component: TicketSidebarParticipants,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketDetailView],
  views: ['agent'],
  icon: 'participants',
  order: 5000,
  available: () => {
    const application = useApplicationStore()
    return Boolean(application.config?.ticket_participants_enabled)
  },
}
