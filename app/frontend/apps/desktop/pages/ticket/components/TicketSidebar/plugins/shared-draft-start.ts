// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarSharedDraftStart from '../TicketSidebarSharedDraftStart/TicketSidebarSharedDraftStart.vue'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Shared Drafts'),
  component: TicketSidebarSharedDraftStart,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketCreate],
  icon: 'file-text',
  order: 3000,
  available: (context) => !!context.formValues.group_id,
}
