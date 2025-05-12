// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FormRef } from '#shared/components/Form/types.ts'
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
  token?: string
}

export interface TwoFactorConfigurationProps {
  type: TwoFactorConfigurationType
  successCallback?: () => void
}

export interface TwoFactorConfigurationComponentProps {
  type: TwoFactorConfigurationType
  options?: ObjectLike
  token?: string
  formSubmitCallback?: (payload: TwoFactorConfigurationActionPayload) => void
  successCallback?: (payload?: unknown) => void
}

// Some components always require token to be passed via props.
export type TwoFactorConfigurationComponentPropsWithRequiredToken = Omit<
  TwoFactorConfigurationComponentProps,
  'token'
> &
  Required<Pick<TwoFactorConfigurationComponentProps, 'token'>>

export interface TwoFactorConfigurationComponentInstance {
  executeAction?: () => Promise<TwoFactorConfigurationActionPayload>
  headerSubtitle?: string
  headerIcon?: string
  form?: FormRef
  footerActionOptions?: ActionFooterOptions
}
