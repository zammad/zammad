// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TwoFactorConfigurationPlugin } from '#shared/entities/two-factor/types.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import TwoFactorConfigurationAuthenticatorApp from '#desktop/components/TwoFactor/TwoFactorConfiguration/TwoFactorConfigurationAuthenticatorApp.vue'

export default {
  name: EnumTwoFactorAuthenticationMethod.AuthenticatorApp,
  editable: true,
  component: TwoFactorConfigurationAuthenticatorApp,
  actionButtonA11yLabel: __('Action menu button for authenticator app'),
  getActionA11yLabel(type) {
    switch (type) {
      case 'setup':
        return __('Set up authenticator app')
      case 'default':
        return __('Set authenticator app as default')
      case 'edit':
        return __('Edit authenticator app')
      case 'remove':
        return __('Remove authenticator app')
      default:
        return ''
    }
  },
} satisfies TwoFactorConfigurationPlugin
