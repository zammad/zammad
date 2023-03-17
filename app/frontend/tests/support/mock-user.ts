// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketView } from '@shared/entities/ticket/types'
import { mockPermissions } from './mock-permissions'

// If we change handling, we can improve it here in one function
export const setupView = (view: TicketView) => {
  mockPermissions([`ticket.${view}`])
}
