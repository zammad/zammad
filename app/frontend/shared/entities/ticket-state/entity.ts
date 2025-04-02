// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { type TicketState } from '#shared/graphql/types.ts'

import type { EntityPlugin } from '../useEntity.ts'

// TODO: add Entity-Data types instead of direct usage from GQL

const ticketStateEntity: EntityPlugin<TicketState> = {
  name: 'TicketState',
  display: (object) => object.name || '',
}

export default ticketStateEntity
