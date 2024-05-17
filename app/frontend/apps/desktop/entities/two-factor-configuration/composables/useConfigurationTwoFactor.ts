// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed, watch } from 'vue'

import { useApplicationConfigTwoFactor } from '#shared/composables/authentication/useApplicationConfigTwoFactor.ts'
import type {
  EnumTwoFactorAuthenticationMethod,
  TwoFactorEnabledAuthenticationMethod,
} from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentTwoFactorUpdatesSubscription } from '#desktop/entities/user/current/graphql/subscriptions/userCurrentTwoFactorUpdates.api.ts'

import type { TwoFactorConfigurationMethod } from '../types.ts'

export const useConfigurationTwoFactor = () => {
  const {
    twoFactorEnabledMethods,
    hasEnabledMethods,
    hasEnabledRecoveryCodes,
  } = useApplicationConfigTwoFactor()

  const session = useSessionStore()
  const { user } = storeToRefs(session)

  const defaultTwoFactorMethod = computed<EnumTwoFactorAuthenticationMethod>(
    () => {
      return user.value?.preferences?.two_factor_authentication?.default
    },
  )

  const userCurrentTwoFactorSubscription = new SubscriptionHandler(
    useUserCurrentTwoFactorUpdatesSubscription({ userId: session.userId }),
  )

  const userCurrentTwoFactorResult = userCurrentTwoFactorSubscription.result()

  const twoFactorConfigurationResult = computed(
    () =>
      userCurrentTwoFactorResult.value?.userCurrentTwoFactorUpdates
        .configuration,
  )

  const enabledAuthenticationMethodLookup = computed(() => {
    return twoFactorConfigurationResult.value?.enabledAuthenticationMethods.reduce(
      (methodLookup, enabledAuthenticationMethod) => {
        methodLookup[enabledAuthenticationMethod.authenticationMethod] = {
          ...enabledAuthenticationMethod,
          default:
            enabledAuthenticationMethod.authenticationMethod ===
            defaultTwoFactorMethod.value,
        }
        return methodLookup
      },
      {} as Record<string, TwoFactorEnabledAuthenticationMethod>,
    )
  })

  const twoFactorConfigurationMethods = computed(() => {
    const mappedMethods: TwoFactorConfigurationMethod[] = []

    twoFactorEnabledMethods.value.forEach((enabledAuthenticationMethod) => {
      const configurationMethod =
        enabledAuthenticationMethodLookup.value?.[
          enabledAuthenticationMethod.name
        ]

      mappedMethods.push({
        ...enabledAuthenticationMethod,
        configured: Boolean(configurationMethod?.configured),
        default: Boolean(configurationMethod?.default),
      })
    })

    return mappedMethods
  })

  const hasConfiguredMethods = computed(() =>
    Object.values(enabledAuthenticationMethodLookup.value || {}).some(
      (enabledAuthenticationMethod) => enabledAuthenticationMethod.configured,
    ),
  )

  const hasRecoveryCodes = computed(() => {
    return Boolean(twoFactorConfigurationResult.value?.recoveryCodesExist)
  })

  // We need to restart the subscription when enabled two factor method list changed.
  watch(twoFactorEnabledMethods, () =>
    userCurrentTwoFactorSubscription.operationResult.restart(),
  )

  return {
    twoFactorConfigurationMethods,
    hasEnabledMethods,
    hasEnabledRecoveryCodes,
    hasConfiguredMethods,
    hasRecoveryCodes,
  }
}
