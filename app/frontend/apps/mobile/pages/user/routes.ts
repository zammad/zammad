// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw = {
  path: '/users/:internalId(\\d+)',
  name: 'UserDetailView',
  props: (route) => ({ internalId: Number(route.params.internalId) }),
  component: () => import('./views/UserDetailView.vue'),
  alias: '/user/profile/:internalId(\\d+)',
  meta: {
    title: __('User'),
    requiresAuth: true,
    // app/assets/javascripts/app/controllers/user_profile.coffee:291
    requiredPermission: ['ticket.agent'],
    hasHeader: true,
    level: 2,
  },
}

export default routes
