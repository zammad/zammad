// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import { TicketSidebarScreenType } from '../../types.ts'
import TicketSidebarAttachmentButton from '../TicketSidebarAttachment/TicketSidebarAttachmentButton.vue'
import TicketSidebarAttachmentContent from '../TicketSidebarAttachment/TicketSidebarAttachmentContent.vue'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Attachments'),
  buttonComponent: TicketSidebarAttachmentButton,
  contentComponent: TicketSidebarAttachmentContent,
  permissions: ['ticket.agent', 'ticket.customer'],
  icon: 'paperclip',
  order: 6000,
  available: (context) => {
    const { config } = useApplicationStore()
    return (
      context.screenType === TicketSidebarScreenType.TicketDetailView &&
      config.ui_ticket_zoom_sidebar_article_attachments
    )
  },
}
