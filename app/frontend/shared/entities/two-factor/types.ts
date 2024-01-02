// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumTwoFactorAuthenticationMethod,
  Scalars,
} from '#shared/graphql/types.ts'

export interface LoginFormData {
  login: string
  password: string
  rememberMe: boolean
}

export interface RecoveryCodeFormData {
  code: string
}

export interface TwoFactorSetupResult {
  success: boolean
  payload?: unknown
  error?: string
  retry?: boolean
}

export interface TwoFactorPlugin {
  name: EnumTwoFactorAuthenticationMethod
  label: string
  description?: string
  order: number
  icon: string
  setup?(data: Scalars['JSON']['input']): Promise<TwoFactorSetupResult>
  form?: boolean
  helpMessage?: string
  errorHelpMessage?: string
}

export interface TwoFactorFormData {
  code: string
}

export interface LoginCredentials {
  login: string
  password: string
  rememberMe: boolean
}

export interface LoginFlow {
  state: 'credentials' | '2fa' | '2fa-select' | 'recovery-code'
  allowedMethods: EnumTwoFactorAuthenticationMethod[]
  defaultMethod?: Maybe<EnumTwoFactorAuthenticationMethod>
  recoveryCodesAvailable: boolean
  twoFactor?: EnumTwoFactorAuthenticationMethod
  credentials?: LoginFormData
}
