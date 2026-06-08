// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumTaskbarEntity } from '#shared/graphql/types.ts'

import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw = {
  path: '/users/:internalId(\\d+)',
  name: 'UserDetailView',
  props: true,
  component: () => import('./views/UserDetailView.vue'),
  alias: '/user/profile/:internalId(\\d+)',
  meta: {
    title: __('User'),
    requiresAuth: true,
    // app/assets/javascripts/app/controllers/user_profile.coffee:2
    requiredPermission: ['ticket.agent', 'admin.user'],
    taskbarTabEntity: EnumTaskbarEntity.UserProfile,
    isTaskbarTabPossible: (route) => !!route.params.internalId,
    messageForbidden: __('You have insufficient rights to view this user.'),
    messageNotFound: __('User with specified ID was not found. Try checking the URL for errors.'),
    level: 2,
  },
}

export default routes
