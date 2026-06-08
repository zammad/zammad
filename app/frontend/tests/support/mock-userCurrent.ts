// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'

import { initializePiniaStore } from './components/renderComponent.ts'

export const mockUserCurrent = (mockUser: Partial<UserData> = {}) => {
  initializePiniaStore()
  const session = useSessionStore()
  session.user = {
    id: convertToGraphQLId('User', 2),
    internalId: 2,
    objectAttributeValues: [],
    preferences: {},
    ...mockUser,
  }
}
