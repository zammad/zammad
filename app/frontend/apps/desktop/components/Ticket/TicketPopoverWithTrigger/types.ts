// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { BadgeVariant } from '#shared/components/CommonBadge/types.ts'
import type { TicketInfoForPopoverQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export type TicketPopoverTicket = ConfidentTake<TicketInfoForPopoverQuery, 'ticket'>

export interface SidebarBadge {
  sidebar: string
  tooltip: string
  variant: BadgeVariant
  label: string
  labelClass?: string
  value: string
  icon?: string
  emoji?: string
}
