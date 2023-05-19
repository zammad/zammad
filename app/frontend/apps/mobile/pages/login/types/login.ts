// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormData } from '#shared/components/Form/types.ts'
import type { EnumTwoFactorMethod } from '#shared/graphql/types.ts'

export interface LoginFormData {
  login: string
  password: string
  rememberMe: boolean
}

export interface TwoFactorFormData {
  code: string
}

export interface LoginFlow {
  state: 'credentials' | '2fa' | '2fa-select'
  allowedMethods: EnumTwoFactorMethod[]
  twoFactor?: EnumTwoFactorMethod
  credentials?: FormData<LoginFormData>
}
