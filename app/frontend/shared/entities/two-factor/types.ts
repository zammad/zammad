// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  EnumTwoFactorAuthenticationMethod,
  Scalars,
} from '#shared/graphql/types.ts'
import type { AppSpecificRecord } from '#shared/types/app.ts'

export interface TwoFactorSetupResult {
  success: boolean
  payload?: unknown
  error?: string
  retry?: boolean
}

export interface TwoFactorPlugin {
  name: EnumTwoFactorAuthenticationMethod
  label: string
  order: number
  icon: AppSpecificRecord<string>
  setup?(data: Scalars['JSON']['input']): Promise<TwoFactorSetupResult>
  form?: boolean
  helpMessage?: string
  errorHelpMessage?: string
}
