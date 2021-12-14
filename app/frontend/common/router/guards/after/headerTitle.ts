// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import useMetaTitle from '@common/composables/useMetaTitle'
import { NavigationHookAfter, RouteLocationNormalized } from 'vue-router'

const headerTitleGuard: NavigationHookAfter = (to: RouteLocationNormalized) => {
  if (to.meta.title) {
    const { setViewTitle } = useMetaTitle()
    setViewTitle(to.meta.title)
  }
}

export default headerTitleGuard
