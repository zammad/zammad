// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects, EnumSearchableModels } from '#shared/graphql/types.ts'

import TicketListTable from '#desktop/components/Ticket/TicketListTable.vue'

import Ticket from '../QuickSearch/entities/Ticket.vue'

import type { SearchPlugin } from '../types.ts'

export default <SearchPlugin>{
  name: EnumSearchableModels.Ticket,
  object: EnumObjectManagerObjects.Ticket,
  label: __('Ticket'),
  priority: 100,
  quickSearchResultLabel: __('Found tickets'),
  quickSearchComponent: Ticket,
  quickSearchResultKey: 'quickSearchTickets',
  permissions: ['ticket.agent', 'ticket.customer'],
  filterPermissions: ['ticket.agent'],
  detailSearchHeaders: (config) => {
    const headers = ['stateIcon', 'number', 'title', 'customer', 'group', 'owner', 'created_at']

    if (config.ui_ticket_priority_icons) {
      headers.unshift('priorityIcon')
    }

    return headers
  },
  detailSearchComponent: TicketListTable,
  filterAttributesOverride: [
    {
      label: __('Ticket number'),
      name: 'ticket.number',
    },
  ],
}
