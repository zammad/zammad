// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { defineStore } from 'pinia'
import { ref } from 'vue'

import useFingerprint from '#shared/composables/useFingerprint.ts'
import { useLoginMutation } from '#shared/graphql/mutations/login.api.ts'
import { useLogoutMutation } from '#shared/graphql/mutations/logout.api.ts'
import {
  type EnumTwoFactorAuthenticationMethod,
  type LoginInput,
} from '#shared/graphql/types.ts'
import { clearApolloClientStore } from '#shared/server/apollo/client.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { useApplicationStore } from './application.ts'
import { resetAndDisposeStores } from './index.ts'
import { useSessionStore } from './session.ts'

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
    const { fingerprint } = useFingerprint()

    const clearAuthentication = async (): Promise<void> => {
      await clearApolloClientStore()

      const session = useSessionStore()
      session.resetCurrentSession()
      authenticated.value = false
      resetAndDisposeStores(true)

      // Refresh the config after logout, to have only the non authenticated version.
      await useApplicationStore().resetAndGetConfig()

      session.initialized = false
    }

    const refreshAfterAuthentication = async (): Promise<void> => {
      await Promise.all([
        useApplicationStore().getConfig(),
        useSessionStore().getCurrentUser(),
      ])
    }

    const logout = async (): Promise<void> => {
      const logoutMutation = new MutationHandler(useLogoutMutation())

      const result = await logoutMutation.send()
      if (result?.logout?.success) {
        if (result.logout.externalLogoutUrl) {
          externalLogout.value = true
          authenticated.value = false
          window.location.href = result.logout.externalLogoutUrl
          return
        }

        await clearAuthentication()

        testFlags.set('logout.success')
      }
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

      const loginMutation = new MutationHandler(
        useLoginMutation({
          variables: {
            input: loginInput,
          },
          context: {
            headers: {
              'X-Browser-Fingerprint': fingerprint.value,
            },
          },
        }),
      )

      const result = await loginMutation.send()

      if (result?.login?.errors || !result) {
        return Promise.reject(result?.login?.errors)
      }

      await setAuthenticatedSessionId(result.login?.session?.id || null)

      return {
        twoFactor: result.login?.twoFactorRequired,
        afterAuth: result.login?.session?.afterAuth,
      }
    }

    return {
      authenticated,
      externalLogout,
      clearAuthentication,
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
