// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { initializePiniaStore } from './components/renderComponent.ts'
import { nullableMock } from './utils.ts'

export const mockUserCurrent = (mockUser: DeepPartial<UserData> = {}) => {
  initializePiniaStore()
  const session = useSessionStore()
  session.user = nullableMock({
    __typename: 'User',
    id: convertToGraphQLId('User', 2),
    internalId: 2,
    objectAttributeValues: [],
    preferences: {},
    permissions: null,
    ...mockUser,
  }) as UserData
}
