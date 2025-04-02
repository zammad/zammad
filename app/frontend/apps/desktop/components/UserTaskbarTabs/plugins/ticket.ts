// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { TicketTaskbarTabAttributesFragmentDoc } from '#shared/entities/ticket/graphql/fragments/ticketTaskbarTabAttributes.api.ts'
import {
  EnumTaskbarEntity,
  type Ticket as TicketType,
} from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'

import Ticket from '../Ticket/Ticket.vue'

const entityType = 'Ticket'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.TicketZoom,
  component: Ticket,
  entityType,
  entityDocument: TicketTaskbarTabAttributesFragmentDoc,
  buildEntityTabKey: (route) => `${entityType}-${route.params.internalId}`,
  buildTaskbarTabEntityId: (route) => route.params.internalId,
  buildTaskbarTabParams: (route) => ({ ticket_id: route.params.internalId }),
  buildTaskbarTabLink: (entity?: TicketType, entityKey?: string) => {
    if (!entity?.internalId) {
      if (!entityKey) return
      return `/tickets/${entityKey.split('-')?.[1]}`
    }
    return `/tickets/${entity.internalId}`
  },
  confirmTabRemove: true,
  touchExistingTab: true,
}
