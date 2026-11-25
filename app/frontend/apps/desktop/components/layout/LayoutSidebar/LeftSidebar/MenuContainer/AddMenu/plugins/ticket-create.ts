// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { canCreateTicket } from '#shared/entities/ticket/composables/useTicketCreateView.ts'

import type { AddMenuItem } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/types.ts'

export default {
  key: 'ticket-create',
  permission: ['ticket.agent', 'ticket.customer'],
  order: 100,
  label: __('New ticket'),
  variant: 'secondary',
  show: canCreateTicket,
  icon: 'plus-square-fill',
  link: '/tickets/create',
} as AddMenuItem
