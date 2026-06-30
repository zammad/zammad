// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'

import { initializeStore } from './components/initializeStore.ts'
import { nullableMock } from './utils.ts'

export const mockPermissions = (permissions: string[]) => {
  initializeStore()

  const session = useSessionStore()
  if (!session.user) {
    session.user = nullableMock({
      __typename: 'User',
      id: '123',
      internalId: 1,
      objectAttributeValues: [],
      permissions: {
        __typename: 'UserPermission',
        names: permissions,
      },
    }) as unknown as UserData
  }

  session.user!.permissions = { __typename: 'UserPermission', names: permissions }

  if (Symbol.for('tests.permissions') in globalThis) return

  Object.defineProperty(globalThis, Symbol.for('tests.permissions'), {
    get() {
      const session = useSessionStore()
      return session.user?.permissions || { __typename: 'UserPermission', names: [] }
    },
    configurable: true,
  })
}
