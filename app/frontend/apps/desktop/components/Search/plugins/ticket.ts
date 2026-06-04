// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getTimeAccountingDisplayUnit } from '#shared/entities/ticket/composables/useTicketAccountedTime.ts'
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
  // A function of config so the accounted-time field can carry the configured
  // time-accounting unit (only when one is set) — the label is interpolated and
  // translated at output, so the override stays translation-free.
  filterAttributesOverride: (config) => {
    const accountedTimeUnit = getTimeAccountingDisplayUnit(config)

    return [
      {
        label: __('Ticket number'),
        name: 'ticket.number',
      },
      ...(accountedTimeUnit
        ? [
            {
              name: 'ticket.time_unit',
              label: __('Accounted time - %s'),
              labelPlaceholder: [accountedTimeUnit],
            },
          ]
        : []),
    ]
  },
}
