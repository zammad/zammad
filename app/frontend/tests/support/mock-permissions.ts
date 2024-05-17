// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '#shared/stores/session.ts'

import { initializeStore } from './components/initializeStore.ts'

export const mockPermissions = (permissions: string[]) => {
  initializeStore()

  const session = useSessionStore()
  if (!session.user) {
    session.user = {
      id: '123',
      internalId: 1,
      objectAttributeValues: [],
    }
  }

  session.user!.permissions = { names: permissions }

  if (Symbol.for('tests.permissions') in globalThis) return

  Object.defineProperty(globalThis, Symbol.for('tests.permissions'), {
    get() {
      const session = useSessionStore()
      return session.user?.permissions || { names: [] }
    },
    configurable: true,
  })
}
