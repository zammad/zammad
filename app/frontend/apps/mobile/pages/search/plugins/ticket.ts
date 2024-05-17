// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import TicketItem from '#mobile/components/Ticket/TicketItem.vue'

import type { SearchPlugin } from './index.ts'

export default <SearchPlugin>{
  model: 'Ticket',
  headerLabel: __('Tickets'),
  searchLabel: __('Tickets with "%s"'),
  component: TicketItem,
  link: '/tickets/#{internalId}',
  permissions: ['ticket.agent', 'ticket.customer'],
  icon: { name: 'all-tickets', size: 'base' },
  iconBg: 'bg-blue',
  order: 100,
}
