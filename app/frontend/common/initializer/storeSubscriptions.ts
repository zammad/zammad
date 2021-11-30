// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import useAuthenticatedStore from '@common/stores/authenticated'
import useLocaleStore from '@common/stores/locale'
import useSessionIdStore from '@common/stores/session/id'
import useSessionUserStore from '@common/stores/session/user'
import useApplicationLoadedStore from '@common/stores/application/loaded'

export default function initializeStoreSubscriptions(): void {
  const sessionId = useSessionIdStore()
  const authenticated = useAuthenticatedStore()
  const sessionUser = useSessionUserStore()
  const locale = useLocaleStore()
  const applicationLoaded = useApplicationLoadedStore()

  applicationLoaded.$subscribe(() => {
    sessionId.$subscribe((mutation, state) => {
      if (state.value) {
        authenticated.value = true
      } else {
        authenticated.value = false
        sessionUser.value = null
      }
    })

    sessionUser.$subscribe((mutation, state) => {
      if (!state.value) {
        locale.updateLocale()
      }
    })
  })
}
