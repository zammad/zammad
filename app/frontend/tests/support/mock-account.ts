// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useSessionStore } from '@shared/stores/session'
import type { UserData } from '@shared/types/store'
import { initializeStore } from './components/renderComponent'

export const mockAccount = (mockUser: Partial<UserData>) => {
  initializeStore()
  const user = useSessionStore()
  user.user = { id: '123', objectAttributeValues: [], ...mockUser }
}
