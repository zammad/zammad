// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import useAuthenticatedStore from '@common/stores/authenticated'
import useLocaleStore from '@common/stores/locale'
import useSessionIdStore from '@common/stores/session/id'
import useSessionUserStore from '@common/stores/session/user'
import useTranslationsStore from '@common/stores/translations'

export default function initializeStoreSubscriptions(): void {
  const sessionId = useSessionIdStore()
  const authenticated = useAuthenticatedStore()
  const sessionUser = useSessionUserStore()
  const locale = useLocaleStore()

  sessionId.$subscribe((mutation, state) => {
    if (state.value) {
      authenticated.value = true
      sessionUser.getCurrentUser()
    } else {
      authenticated.value = false
      sessionUser.value = null
    }
  })

  sessionUser.$subscribe(() => {
    locale.updateLocale()
  })

  locale.$subscribe((mutation, state) => {
    useTranslationsStore().load(state.value)
  })
}
