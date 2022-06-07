// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'
import { useSearchPlugins } from './plugins'

const routes: RouteRecordRaw[] = [
  {
    path: '/search/:type?',
    name: 'SearchOverview',
    props: true,
    component: () => import('./views/SearchOverview.vue'),
    beforeEnter(to) {
      const { type } = to.params

      if (!type) return undefined

      const searchPlugins = useSearchPlugins()

      if (Array.isArray(type) || !searchPlugins[type]) {
        return { ...to, params: {} }
      }

      return undefined
    },
    meta: {
      title: __('Search'),
      requiresAuth: true,
      // TODO 2022-06-02 Sheremet V.A. rights?
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      hasBottomNavigation: true,
      level: 3,
    },
  },
]

export default routes
