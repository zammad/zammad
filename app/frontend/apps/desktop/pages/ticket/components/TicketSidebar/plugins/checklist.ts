// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import { TicketSidebarScreenType } from '../../types.ts'
import TicketSidebarChecklistButton from '../TicketSidebarChecklist/TicketSidebarChecklistButton.vue'
import TicketSidebarChecklistContent from '../TicketSidebarChecklist/TicketSidebarChecklistContent.vue'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Checklist'),
  buttonComponent: TicketSidebarChecklistButton,
  contentComponent: TicketSidebarChecklistContent,
  permissions: ['ticket.agent'],
  icon: 'checklist',
  order: 5000,
  available: (context) => {
    const { config } = useApplicationStore()
    return (
      context.screenType === TicketSidebarScreenType.TicketDetailView &&
      config.checklist
    )
  },
}
