// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

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
  },
}

export default route
