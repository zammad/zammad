// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumTaskbarEntity,
  type UserTaskbarItemEntityTicketCreate,
} from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'

import TicketCreate from '../Ticket/TicketCreate.vue'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.TicketCreate,
  component: TicketCreate,
  buildEntityTabKey: (route) => `TicketCreateScreen-${route.params.tabId}`,
  buildTaskbarTabEntityId: (route) => route.params.tabId,
  buildTaskbarTabParams: (route) => ({ id: route.params.tabId }),
  buildTaskbarTabLink: (entity?: UserTaskbarItemEntityTicketCreate) => {
    if (!entity?.uid) return
    return `/tickets/create/${entity.uid}`
  },
  confirmTabRemove: true,
}
