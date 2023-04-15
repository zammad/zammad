// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketState } from '@shared/entities/ticket/types'
import type { EnumTicketStateColorCode } from '@shared/graphql/types'

export interface TicketItemData {
  id: string
  internalId: number
  title: string
  number: string
  state: {
    name: TicketState | string
  }
  priority?: {
    name: string
    defaultCreate: boolean
    uiColor?: Maybe<string>
  }
  customer?: {
    fullname?: Maybe<string>
  }
  updatedAt?: string
  updatedBy?: Maybe<{
    id: string
    fullname?: Maybe<string>
  }>
  stateColorCode: EnumTicketStateColorCode
}
