// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '@shared/stores/session'
import { initializeStore } from './components/renderComponent'

export const mockPermissions = (permissions: string[]) => {
  initializeStore()

  const session = useSessionStore()
  if (!session.user) {
    session.user = {
      id: '123',
      objectAttributeValues: [],
    }
  }

  session.user!.permissions = { names: permissions }
}
