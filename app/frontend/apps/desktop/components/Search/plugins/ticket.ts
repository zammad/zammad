// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { EnumSearchableModels } from '#shared/graphql/types.ts'

import TicketListTable from '#desktop/components/Ticket/TicketListTable.vue'

import Ticket from '../QuickSearch/entities/Ticket.vue'

import type { SearchPlugin } from '../types.ts'

export default <SearchPlugin>{
  name: EnumSearchableModels.Ticket,
  label: __('Ticket'),
  priority: 100,
  quickSearchResultLabel: __('Found tickets'),
  quickSearchComponent: Ticket,
  quickSearchResultKey: 'quickSearchTickets',
  permissions: ['ticket.agent', 'ticket.customer'],
  detailSearchHeaders: [
    'number',
    'title',
    'customer',
    'group',
    'owner',
    'created_at',
  ], // TODO: maybe add possibility of a function, because of generic stuff like priority icon etc.
  detailSearchComponent: TicketListTable,
}
