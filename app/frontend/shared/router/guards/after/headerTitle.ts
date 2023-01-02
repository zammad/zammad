// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { NavigationHookAfter, RouteLocationNormalized } from 'vue-router'
import useMetaTitle from '@shared/composables/useMetaTitle'

const headerTitleGuard: NavigationHookAfter = (to: RouteLocationNormalized) => {
  if (to.meta.title) {
    const { setViewTitle } = useMetaTitle()
    setViewTitle(to.meta.title)
  }
}

export default headerTitleGuard
