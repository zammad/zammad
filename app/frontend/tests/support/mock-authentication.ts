// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useAuthenticationStore } from '@shared/stores/authentication'
import { initializeStore } from './components/renderComponent'

export const mockAuthentication = (authenticated: boolean) => {
  initializeStore()

  const authentication = useAuthenticationStore()
  authentication.authenticated = authenticated
}
