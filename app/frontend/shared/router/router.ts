// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { type Router } from 'vue-router'

let routerInstance: Router

export const setCurrentRouter = (router: Router) => {
  routerInstance = router
}

export const getCurrentRouter = () => routerInstance
