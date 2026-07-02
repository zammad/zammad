// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ReferencingTicket } from '#shared/entities/ticket/types.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

export type { ReferencingTicket } from '#shared/entities/ticket/types.ts'

export interface TicketReferenceMenuItem extends MenuItem {
  ticket: ReferencingTicket
}
