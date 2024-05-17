// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import type { TwoFactorPlugin } from '../types.ts'

export default {
  name: EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
  label: __('Authenticator App'),
  description: __(
    'Get the security code from the authenticator app on your device.',
  ),
  order: 200,
  icon: '2fa-authenticator-app',
  loginOptions: {
    helpMessage: __('Enter the code from your two-factor authenticator app.'),
  },
} satisfies TwoFactorPlugin
