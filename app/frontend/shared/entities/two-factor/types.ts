// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumTwoFactorAuthenticationMethod,
  Scalars,
} from '#shared/graphql/types.ts'

import type { Component } from 'vue'

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

export interface TwoFactorLoginOptions {
  setup?(data: Scalars['JSON']['input']): Promise<TwoFactorSetupResult>
  form?: boolean
  helpMessage?: string
  errorHelpMessage?: string
}

export type TwoFactorActionTypes = 'setup' | 'edit' | 'default' | 'remove'
export interface TwoFactorConfigurationOptions {
  setup?(data: Scalars['JSON']['input']): Promise<TwoFactorSetupResult>
  component: Component
  editable?: boolean
  actionButtonA11yLabel: string
  getActionA11yLabel(type: TwoFactorActionTypes): string
}

export interface TwoFactorConfigurationPlugin
  extends TwoFactorConfigurationOptions {
  name: EnumTwoFactorAuthenticationMethod
}

export interface TwoFactorPlugin {
  name: EnumTwoFactorAuthenticationMethod
  label: string
  description?: string
  order: number
  icon: string
  loginOptions: TwoFactorLoginOptions
  configurationOptions?: TwoFactorConfigurationOptions
}

export interface TwoFactorLoginFormData {
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
