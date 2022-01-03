// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Home from '@mobile/views/Home.vue'
import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw = {
  path: '/',
  name: 'Home',
  props: true,
  component: Home,
  meta: {
    title: __('Home'),
    requiresAuth: true,
    requiredPermission: ['*'],
    hasBottomNavigation: true,
    level: 1,
  },
}

export default route
