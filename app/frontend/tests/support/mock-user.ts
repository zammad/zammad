// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mockPermissions } from './mock-permissions'

// If we change handling, we can improve it here in one function
export const setupView = (view: 'agent' | 'customer') => {
  mockPermissions([`ticket.${view}`])
}
