// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

export default {
  type: EntityType.Ticket,
  component: () => import('#desktop/components/CommonSimpleEntityList/entity/TicketEntity.vue'),
  emptyMessage: __('No results found'),
}
