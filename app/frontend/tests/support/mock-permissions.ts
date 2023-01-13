// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '@shared/stores/session'
import { initializePiniaStore } from './components/renderComponent'

export const mockPermissions = (permissions: string[]) => {
  initializePiniaStore()

  const session = useSessionStore()
  if (!session.user) {
    session.user = {
      id: '123',
      internalId: 1,
      objectAttributeValues: [],
    }
  }

  session.user!.permissions = { names: permissions }
}
