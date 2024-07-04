// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  TicketSidebarScreenType,
  type TicketSidebarContext,
} from '../../types.ts'
import TicketSidebarSharedDraftStartButton from '../TicketSidebarSharedDraftStartButton.vue'
import TicketSidebarSharedDraftStartContent from '../TicketSidebarSharedDraftStartContent.vue'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Shared Drafts'),
  buttonComponent: TicketSidebarSharedDraftStartButton,
  contentComponent: TicketSidebarSharedDraftStartContent,
  permissions: ['ticket.agent'],
  icon: 'file-text',
  order: 3000,
  available: (context: TicketSidebarContext) =>
    context.screenType === TicketSidebarScreenType.TicketCreate &&
    !!context.formValues.group_id,
}
