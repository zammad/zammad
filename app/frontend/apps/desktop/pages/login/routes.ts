// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useThirdPartyAuthentication } from '#shared/composables/useThirdPartyAuthentication.ts'

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
      sidebar: false,
    },
  },
  {
    path: '/admin-password-auth',
    name: 'AdminPasswordAuth',
    component: () => import('./views/AdminPasswordAuth.vue'),
    async beforeEnter(to) {
      const application = useApplicationStore()
      const { hasEnabledProviders } = useThirdPartyAuthentication()

      if (application.config.user_show_password_login) {
        return to.redirectedFrom ? false : '/'
      }

      if (!hasEnabledProviders.value) {
        return to.redirectedFrom ? false : '/'
      }

      return true
    },
    meta: {
      title: __('Admin Password Login'),
      requiresAuth: false,
      requiredPermission: null,
      hasOwnLandmarks: true,
      sidebar: false,
    },
  },
  // TODO: after-auth
  // {
  //   path: '/login/after-auth',
  //   name: 'LoginAfterAuth',
  //   component: () => import('./views/LoginAfterAuth.vue'),
  //   async beforeEnter(to) {
  //     // don't open the page if there is nothing to show
  //     const { useAfterAuthPlugins } = await import(
  //       './after-auth/composable/useAfterAuthPlugins.ts'
  //     )
  //     const { currentPlugin } = useAfterAuthPlugins()
  //     if (!currentPlugin.value) {
  //       return to.redirectedFrom ? false : '/'
  //     }
  //   },
  //   meta: {
  //     requiresAuth: false,
  //     requiredPermission: null,
  //     hasOwnLandmarks: true,
  //   },
  // },
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
