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
      if (cleanup) {
        logoutCleanup.forEach((cleanupCallback) => cleanupCallback())
      }

      await clearApolloClientStore()

      resetAndDisposeStores(true)

      const session = useSessionStore()

      session.resetCurrentSession()
      authenticated.value = false

      // Refresh the config after logout, to have only the non authenticated version.
      useApplicationStore().resetAndGetConfig()

      session.initialized = false
    }

    const refreshAfterAuthentication = async (): Promise<void> => {
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
      )

      stopAllQueryPollings()

      logoutCleanup.forEach((cleanupCallback) => cleanupCallback())

      const result = await logoutMutation.send()

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
