// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'
import type { TwoFactorPlugin } from '../types.ts'

export default {
  name: EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
  label: __('Authenticator App'),
  order: 200,
  helpMessage: __('Enter the code from your two-factor authenticator app.'),
  icon: {
    mobile: 'mobile-mobile-code',
  },
} satisfies TwoFactorPlugin
