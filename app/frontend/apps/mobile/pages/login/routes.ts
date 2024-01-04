// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

export const isMainRoute = true

const route: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('./views/Login.vue'),
    meta: {
      title: __('Sign in'),
      requiresAuth: false,
      requiredPermission: null,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/login/after-auth',
    name: 'LoginAfterAuth',
    component: () => import('./views/LoginAfterAuth.vue'),
    async beforeEnter(to) {
      // don't open the page if there is nothing to show
      const { useAfterAuthPlugins } = await import(
        './after-auth/composable/useAfterAuthPlugins.ts'
      )
      const { currentPlugin } = useAfterAuthPlugins()
      if (!currentPlugin.value) {
        return to.redirectedFrom ? false : '/'
      }
    },
    meta: {
      requiresAuth: false,
      requiredPermission: null,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/logout',
    name: 'Logout',
    component: {
      async beforeRouteEnter() {
        const [{ useAuthenticationStore }, { useNotifications }] =
          await Promise.all([
            import('#shared/stores/authentication.ts'),
            import(
              '#shared/components/CommonNotifications/useNotifications.ts'
            ),
          ])

        const { clearAllNotifications } = useNotifications()

        const authentication = useAuthenticationStore()

        clearAllNotifications()
        await authentication.logout()

        if (authentication.externalLogout) return false

        return '/login'
      },
    },
    meta: {
      requiresAuth: false,
      requiredPermission: null,
    },
  },
]

export default route
