// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import useAuthenticatedStore from '@common/stores/authenticated'
import useSessionIdStore from '@common/stores/session/id'
import useSessionUserStore from '@common/stores/session/user'

export default function initialize(): void {
  const sessionId = useSessionIdStore()
  const authenticated = useAuthenticatedStore()
  const sessionUser = useSessionUserStore()

  sessionId.$subscribe((mutation, state) => {
    if (state.value) {
      authenticated.value = true
      sessionUser.getCurrentUser()
    } else {
      authenticated.value = false
      sessionUser.value = null
    }
  })
}
