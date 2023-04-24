// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'
import { initializePiniaStore } from './components/renderComponent.ts'

export const mockAccount = (mockUser: Partial<UserData>) => {
  initializePiniaStore()
  const user = useSessionStore()
  user.user = {
    id: '123',
    internalId: 1,
    objectAttributeValues: [],
    ...mockUser,
  }
}
