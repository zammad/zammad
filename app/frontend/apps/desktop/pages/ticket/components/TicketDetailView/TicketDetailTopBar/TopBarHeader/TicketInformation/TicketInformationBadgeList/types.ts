// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Ticket } from '#shared/graphql/types.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

export type ReferencingTicket = Pick<
  Ticket,
  'id' | 'internalId' | 'number' | 'title' | 'state' | 'stateColorCode'
>

export interface TicketReferenceMenuItem extends MenuItem {
  ticket: ReferencingTicket
}
