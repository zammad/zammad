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
      redirectToDefaultRoute: true,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/admin-password-auth',
    name: 'AdminPasswordAuth',
    component: () => import('./views/AdminPasswordAuth.vue'),
    meta: {
      title: __('Admin Password Login'),
      requiresAuth: false,
      requiredPermission: null,
      redirectToDefaultRoute: true,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/login/after-auth',
    name: 'LoginAfterAuth',
    component: () => import('./views/LoginAfterAuth.vue'),
    meta: {
      requiresAuth: true,
      requiredPermission: null,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/reset-password',
    name: 'PasswordReset',
    component: () => import('./views/PasswordReset.vue'),
    meta: {
      requiresAuth: false,
      requiredPermission: null,
      redirectToDefaultRoute: true,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/reset-password/verify/:token?',
    name: 'PasswordResetVerify',
    props: true,
    component: () => import('./views/PasswordResetVerify.vue'),
    meta: {
      requiresAuth: false,
      requiredPermission: null,
      redirectToDefaultRoute: true,
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
  {
    path: '/signup',
    name: 'Signup',
    component: () => import('./views/Signup.vue'),
    meta: {
      title: __('Sign up'),
      requiresAuth: false,
      requiredPermission: null,
      redirectToDefaultRoute: true,
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/signup/verify/:token?',
    name: 'SignupVerify',
    props: true,
    component: () => import('./views/SignupVerify.vue'),
    meta: {
      title: __('Email Verification'),
      requiresAuth: false,
      requiredPermission: null,
      redirectToDefaultRoute: true,
      hasOwnLandmarks: true,
    },
  },
]

export default route
