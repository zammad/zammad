// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { ActionFooterOptions } from '../CommonFlyout/types.ts'

export type TwoFactorConfigurationType =
  | EnumTwoFactorAuthenticationMethod
  | 'password_check'
  | 'recovery_codes'
  | 'removal_confirmation'
  | 'method_list'

export interface TwoFactorConfigurationActionPayload {
  nextState?: TwoFactorConfigurationType
  options?: ObjectLike
}

export interface TwoFactorConfigurationProps {
  type: TwoFactorConfigurationType
  successCallback?: () => void
}

export interface TwoFactorConfigurationComponentProps {
  type: TwoFactorConfigurationType
  options?: ObjectLike
  formSubmitCallback?: (payload: TwoFactorConfigurationActionPayload) => void
  successCallback?: () => void
}

export interface TwoFactorConfigurationComponentInstance {
  executeAction?: () => Promise<TwoFactorConfigurationActionPayload>
  headerSubtitle?: string
  headerIcon?: string
  footerActionOptions?: ActionFooterOptions
}
