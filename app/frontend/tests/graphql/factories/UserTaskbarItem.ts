// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumTaskbarEntity,
  EnumTaskbarEntityAccess,
  EnumTicketStateColorCode,
  type UserTaskbarItem,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<UserTaskbarItem> => {
  return {
    __typename: 'UserTaskbarItem',
    id: convertToGraphQLId('Taskbar', 1),
    key: 'Ticket-1',
    callback: EnumTaskbarEntity.TicketZoom,
    entityAccess: EnumTaskbarEntityAccess.Granted,
    entity: {
      __typename: 'Ticket',
      id: convertToGraphQLId('Ticket', 1),
      internalId: 1,
      number: '53001',
      title: 'Welcome to Zammad!',
      stateColorCode: EnumTicketStateColorCode.Open,
      state: {
        __typename: 'TicketState',
        name: 'open',
      },
      updatedAt: '2024-07-29T09:39:03.000',
      checklist: null,
      referencingChecklistTickets: [],
    },
    dirty: true,
    formNewArticlePresent: false,
  }
}
