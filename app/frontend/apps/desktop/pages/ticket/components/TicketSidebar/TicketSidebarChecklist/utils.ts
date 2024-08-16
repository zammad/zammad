// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  type ChecklistItem as ChecklistItemType,
  EnumChecklistItemTicketAccess,
} from '#shared/graphql/types.ts'

/**
 * Value for `item.ticketAccess`
 * @info - `Granted` - A ticket checklist item, and the agent has access to it.
 * @info - `Forbidden` - A ticket checklist item, and the agent has no access to it.
 * @info - `null` - A regular checklist item, not a ticket checklist item.
 * */
export const verifyAccess = (item: ChecklistItemType) => {
  if (item.ticketAccess === EnumChecklistItemTicketAccess.Granted) return true
  return item.ticketAccess !== EnumChecklistItemTicketAccess.Forbidden
}
