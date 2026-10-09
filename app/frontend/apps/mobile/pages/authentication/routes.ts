// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useAfterAuthPlugins } from './after-auth/composable/useAfterAuthPlugins.ts'

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
    beforeEnter(to) {
      // don't open the page if there is nothing to show
      const { currentPlugin } = useAfterAuthPlugins()
      if (!currentPlugin.value) return to.redirectedFrom ? false : '/'
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
        const [{ useAuthenticationStore }, { useNotifications }, { usePushNotificationsStore }] =
          await Promise.all([
            import('#shared/stores/authentication.ts'),
            import('#shared/components/CommonNotifications/useNotifications.ts'),
            import('#mobile/entities/user/current/stores/pushNotifications.ts'),
          ])

        const { clearAllNotifications } = useNotifications()

        const authentication = useAuthenticationStore()

        clearAllNotifications()

        // Needs the session, so it has to happen before the logout itself.
        //   A device that keeps receiving the notifications of a user who
        //   logged out must not happen, but a failure must not block the logout.
        await usePushNotificationsStore()
          .unregisterDevice()
          .catch((error) => console.error(error))

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
