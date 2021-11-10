// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { RouteRecordRaw } from 'vue-router'
import Login from '@mobile/views/Login.vue'
import Home from '@mobile/views/Home.vue'

// TODO ...extend "meta" in RouteRecordRaw with real type behind.

const routes: Array<RouteRecordRaw> = [
  {
    path: '/login',
    name: 'Login',
    props: true,
    component: Login,
    meta: {},
  },
  {
    path: '/',
    name: 'Home',
    props: true,
    component: Home,
    meta: {
      requiresAuth: true,
    },
  },
]

export default routes
