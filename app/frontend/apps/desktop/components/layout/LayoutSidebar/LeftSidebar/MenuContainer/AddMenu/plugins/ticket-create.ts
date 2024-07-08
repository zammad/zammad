// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { AddMenuItem } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/types.ts'

export default {
  key: 'ticket-create',
  permission: ['ticket.agent', 'ticket.customer'],
  order: 100,
  label: __('New ticket'),
  variant: 'secondary',
  show() {
    const { config } = useApplicationStore()
    const { user } = useSessionStore()

    if (user?.permissions?.names.includes('ticket.agent')) return true

    return config.customer_ticket_create
  },
  icon: 'plus-square-fill',
  link: '/tickets/create',
} as AddMenuItem
