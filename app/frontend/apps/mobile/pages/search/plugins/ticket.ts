// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import TicketItem from '@mobile/components/Ticket/TicketItem.vue'
import type { SearchPlugin } from './index'

export default <SearchPlugin>{
  model: 'Ticket',
  headerLabel: __('Tickets'),
  component: TicketItem,
  link: '/tickets/#{internalId}',
  permissions: ['ticket.agent', 'ticket.customer'],
  icon: { name: 'stack', size: 'base' },
  iconBg: 'bg-blue',
  order: 100,
}
