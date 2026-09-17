// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { defineStore } from 'pinia'
import { ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import useFingerprint from '#shared/composables/useFingerprint.ts'
import { stopAllQueryPollings } from '#shared/composables/useQueryPolling.ts'
import { useLoginMutation } from '#shared/graphql/mutations/login.api.ts'
import { useLogoutMutation } from '#shared/graphql/mutations/logout.api.ts'
import { type EnumTwoFactorAuthenticationMethod, type LoginInput } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { clearApolloClientStore } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { cancelActiveSubscriptions } from '#shared/server/apollo/link/trackSubscriptions.ts'
import { setAuthenticationInvalidated } from '#shared/server/apollo/utils/authenticationState.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { useApplicationStore } from './application.ts'
import { resetAndDisposeStores } from './index.ts'
import { useSessionStore } from './session.ts'

const FORCE_RELOAD_TIMEOUT = 1000

interface LoginOptions {
  login: string
  password: string
  rememberMe: boolean
  twoFactorAuthentication?: {
    method: EnumTwoFactorAuthenticationMethod
    payload: unknown
  }
  recoveryCode?: string
}

export const useAuthenticationStore = defineStore(
  'authentication',
  () => {
    const authenticated = useLocalStorage<boolean>('authenticated', false)
    const externalLogout = ref(false)
    const logoutCleanup = new Set<() => void>()

    const { fingerprint } = useFingerprint()

    const registerLogoutCleanup = (cleanupCallback: () => void) => {
      logoutCleanup.add(cleanupCallback)
    }

    const clearAuthentication = async (cleanup = true): Promise<void> => {
      setAuthenticationInvalidated(true)

      if (cleanup) {
        logoutCleanup.forEach((cleanupCallback) => cleanupCallback())
      }

      // Cancel all running subscriptions before the session is reset, because
      //  resetting it reopens the web socket connection, which would execute
      //  them again on the then unauthenticated connection.
      cancelActiveSubscriptions()

      await clearApolloClientStore()

      resetAndDisposeStores(true)

      const session = useSessionStore()

      session.resetCurrentSession()
      authenticated.value = false

      // Refresh the config after logout, to have only the non authenticated version.
      await useApplicationStore().resetAndGetConfig()

      session.initialized = false
    }

    const refreshAfterAuthentication = async (): Promise<void> => {
      // The authentication is alive again, no matter which path restored it: a
      //  login in this tab, or a session which was picked up after another tab
      //  logged in. Forget a previous invalidation before the first
      //  authenticated operation is started, otherwise the Apollo layer would
      //  keep silencing the authentication errors of the new session, too.
      setAuthenticationInvalidated(false)

      await Promise.all([useApplicationStore().getConfig(), useSessionStore().getCurrentUser()])
    }

    const logout = async (): Promise<void> => {
      const logoutMutation = new MutationHandler(
        useLogoutMutation({
          context: {
            batch: {
              active: false,
            },
          },
        }),
        {
          // The logout continues locally in any case (see below), so a failed
          //  mutation is nothing the user could act on.
          errorShowNotification: false,
        },
      )

      setAuthenticationInvalidated(true)

      stopAllQueryPollings()

      // Stop talking to the server before the session is destroyed, so that the
      //  subscriptions are also removed on the server side.
      cancelActiveSubscriptions()

      logoutCleanup.forEach((cleanupCallback) => cleanupCallback())

      // The logout mutation itself can still fail, for example when the
      //  connection is gone or the session was already destroyed on the server
      //  side. Continue with the local logout in that case: the client side of
      //  the session is torn down at this point - polling is stopped, the
      //  subscriptions are cancelled and the cleanup callbacks ran, none of
      //  which can be taken back - so staying authenticated would leave the
      //  application unable to talk to the server at all.
      const result = await logoutMutation.send().catch(() => null)

      if (result?.logout?.externalLogoutUrl) {
        externalLogout.value = true
        authenticated.value = false
        // No success hooks for external redirect scenario.
        window.location.href = result.logout.externalLogoutUrl
        return
      }

      // Logout cleanup is already done before, so we are setting it to false.
      await clearAuthentication(false)

      testFlags.set('logout.success')
    }

    const setAuthenticatedSessionId = async (newSessionId: string | null) => {
      if (!newSessionId) return false

      const session = useSessionStore()
      session.id = newSessionId
      authenticated.value = true

      // The invalidation is reset inside, before any authenticated operation.
      await refreshAfterAuthentication()

      session.initialized = true

      return true
    }

    const login = async ({
      login,
      password,
      rememberMe,
      twoFactorAuthentication,
      recoveryCode,
    }: LoginOptions) => {
      const loginInput: LoginInput = {
        login,
        password,
        rememberMe,
      }

      if (twoFactorAuthentication) {
        loginInput.twoFactorAuthentication = {
          twoFactorMethod: twoFactorAuthentication.method,
          twoFactorPayload: twoFactorAuthentication.payload,
        }
      } else if (recoveryCode) {
        loginInput.twoFactorRecovery = {
          recoveryCode,
        }
      }

      const showForcedReloadNotification = (reloadTimeout: number) => {
        const { notify } = useNotifications()

        let totalDisplayTime = -1000 // account for initial notification delay

        const callback = () => window.location.reload()

        const interval = setInterval(() => {
          totalDisplayTime += FORCE_RELOAD_TIMEOUT

          const timeRemaining = reloadTimeout - totalDisplayTime

          notify({
            id: 'invalid-csrf-token',
            message: i18n.t(
              'Security token verification failed. This may be just temporary, please reload and try again. Reloading in %s second(s)…',
              Math.ceil(timeRemaining / 1000),
            ),
            type: NotificationTypes.Warn,
            persistent: true,
            actionLabel: __('Reload now'),
            actionCallback: callback,
          })
          if (totalDisplayTime < reloadTimeout) return

          clearInterval(interval)
          callback() // actual forced reload
        }, FORCE_RELOAD_TIMEOUT)
      }

      const loginMutation = new MutationHandler(
        useLoginMutation({
          variables: {
            input: loginInput,
          },
          context: {
            headers: {
              'X-Browser-Fingerprint': fingerprint.value,
            },
            batch: {
              active: false,
            },
          },
        }),
        {
          // A failed login reports itself as an authentication error, and its
          //  message is only visible in the notification.
          errorShowNotificationOnNotAuthorized: true,
          errorCallback: (error) => {
            if (error.type === GraphQLErrorTypes.InvalidCsrfToken) {
              showForcedReloadNotification(10000)
              return false // skip showing an extra error toast
            }

            return true
          },
        },
      )

      const result = await loginMutation.send()

      if (result?.login?.errors || !result) {
        return Promise.reject(result?.login?.errors)
      }

      await setAuthenticatedSessionId(result.login?.session?.id || null)

      externalLogout.value = false

      return {
        twoFactor: result.login?.twoFactorRequired,
        afterAuth: result.login?.session?.afterAuth,
      }
    }

    return {
      authenticated,
      externalLogout,
      clearAuthentication,
      registerLogoutCleanup,
      logout,
      login,
      refreshAfterAuthentication,
      setAuthenticatedSessionId,
    }
  },
  {
    requiresAuth: false,
  },
)
