// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AlertVariant } from '#shared/components/CommonAlert/types.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { EnumChannelArea } from '#shared/graphql/types.ts'

export interface TicketChannelAlert {
  text: string
  textPlaceholder?: string
  variant: AlertVariant
}

export interface TicketChannelPlugin {
  area: EnumChannelArea
  channelAlert(ticket: TicketById): TicketChannelAlert | null
}
