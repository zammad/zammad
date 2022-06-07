// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { TicketState } from '@shared/entities/ticket/types'

// TODO 2022-05-31 Sheremet V.A. base types on actual usage
export interface TicketItemData {
  id: string
  title: string
  number: string
  state: TicketState
  // TODO 2022-06-01 Sheremet V.A.
  priority?: {
    name: string
    uiColor?: Maybe<string>
  }
  owner?: {
    firstname?: Maybe<string>
    lastname?: Maybe<string>
  }
  updatedAt?: string
  updatedBy?: {
    id: string
    firstname?: Maybe<string>
    lastname?: Maybe<string>
  }
}
