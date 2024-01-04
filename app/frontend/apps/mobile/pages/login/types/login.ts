// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSubmitData } from '#shared/components/Form/types.ts'
import type { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

export interface LoginFormData {
  login: string
  password: string
  rememberMe: boolean
}

export interface TwoFactorFormData {
  code: string
}

export interface RecoveryCodeFormData {
  code: string
}

export interface LoginFlow {
  state: 'credentials' | '2fa' | '2fa-select' | 'recovery-code'
  allowedMethods: EnumTwoFactorAuthenticationMethod[]
  recoveryCodesAvailable: boolean
  twoFactor?: EnumTwoFactorAuthenticationMethod
  credentials?: FormSubmitData<LoginFormData>
}
