// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, reactive } from 'vue'

import { useTwoFactorPlugins } from '#shared/entities/two-factor/composables/useTwoFactorPlugins.ts'
import type {
  LoginFlow,
  LoginCredentials,
} from '#shared/entities/two-factor/types.ts'
import type {
  EnumTwoFactorAuthenticationMethod,
  UserLoginTwoFactorMethods,
} from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

const { twoFactorMethodLookup, twoFactorMethods } = useTwoFactorPlugins()

const useLoginTwoFactor = (clearErrors: () => void) => {
  const application = useApplicationStore()

  const loginFlow = reactive<LoginFlow>({
    state: 'credentials',
    allowedMethods: [],
    defaultMethod: undefined,
    recoveryCodesAvailable: false,
  })

  const states = ref<LoginFlow['state'][]>([loginFlow.state])

  const updateState = (state: LoginFlow['state'], skipClearErrors = false) => {
    if (!skipClearErrors) clearErrors()
    states.value.push(state)
    loginFlow.state = state
  }

  const updateSecondFactor = (
    factor: EnumTwoFactorAuthenticationMethod,
    skipClearErrors = false,
  ) => {
    if (!skipClearErrors) clearErrors()
    loginFlow.twoFactor = factor
    updateState('2fa', true)
  }

  const askTwoFactor = (
    twoFactor: UserLoginTwoFactorMethods,
    formData: LoginCredentials,
  ) => {
    clearErrors()
    loginFlow.credentials = formData
    loginFlow.recoveryCodesAvailable = twoFactor.recoveryCodesAvailable
    loginFlow.allowedMethods = twoFactor.availableTwoFactorAuthenticationMethods
    loginFlow.defaultMethod = twoFactor.defaultTwoFactorAuthenticationMethod
    updateSecondFactor(
      twoFactor.defaultTwoFactorAuthenticationMethod as EnumTwoFactorAuthenticationMethod,
      true,
    )
  }

  const twoFactorAllowedMethods = computed(() => {
    return twoFactorMethods.filter((method) =>
      loginFlow.allowedMethods.includes(method.name),
    )
  })

  const twoFactorPlugin = computed(() => {
    return loginFlow.twoFactor
      ? twoFactorMethodLookup[loginFlow.twoFactor]
      : undefined
  })

  const hasAlternativeLoginMethod = computed(() => {
    return (
      twoFactorAllowedMethods.value.length > 1 ||
      loginFlow.recoveryCodesAvailable
    )
  })

  const statePreviousMap = {
    credentials: null,
    '2fa': 'credentials',
    '2fa-select': '2fa',
    'recovery-code': '2fa-select',
  } satisfies Record<string, LoginFlow['state'] | null>

  const goBack = () => {
    clearErrors()
    const previousState = statePreviousMap[loginFlow.state] || 'credentials'
    loginFlow.state = previousState
    // if we go to the first state, reset credentials
    if (previousState === 'credentials') {
      loginFlow.credentials = undefined
    }
  }

  const cancelAndGoBack = () => {
    clearErrors()
    loginFlow.state = 'credentials'
    loginFlow.credentials = undefined
  }

  const loginPageTitle = computed(() => {
    const productName = application.config.product_name
    if (loginFlow.state === 'credentials') return productName
    if (loginFlow.state === 'recovery-code') return __('Recovery Code')
    if (loginFlow.state === '2fa') {
      return twoFactorPlugin.value?.label ?? productName
    }
    return __('Try Another Method')
  })

  return {
    loginFlow,
    hasAlternativeLoginMethod,
    askTwoFactor,
    twoFactorPlugin,
    twoFactorAllowedMethods,
    updateState,
    updateSecondFactor,
    goBack,
    cancelAndGoBack,
    statePreviousMap,
    loginPageTitle,
  }
}

export default useLoginTwoFactor
