// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'

import { initializePiniaStore } from './components/renderComponent.ts'

export const mockUserCurrent = (mockUser: Partial<UserData> = {}) => {
  initializePiniaStore()
  const session = useSessionStore()
  session.user = {
    id: '123',
    internalId: 1,
    objectAttributeValues: [],
    preferences: {},
    ...mockUser,
  }
}
