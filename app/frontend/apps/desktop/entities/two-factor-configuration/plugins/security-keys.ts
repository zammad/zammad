// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TwoFactorConfigurationPlugin } from '#shared/entities/two-factor/types.ts'
import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import TwoFactorConfigurationSecurityKeys from '#desktop/components/TwoFactor/TwoFactorConfiguration/TwoFactorConfigurationSecurityKeys.vue'

export default {
  name: EnumTwoFactorAuthenticationMethod.SecurityKeys,
  editable: true,
  component: TwoFactorConfigurationSecurityKeys,
  actionButtonA11yLabel: __('Action menu button for security keys'),
  getActionA11yLabel(type) {
    switch (type) {
      case 'setup':
        return __('Set up security keys')
      case 'default':
        return __('Set security keys as default')
      case 'edit':
        return __('Edit security keys')
      case 'remove':
        return __('Remove security keys')
      default:
        return ''
    }
  },
  async setup(publicKeyOptions: PublicKeyCredentialCreationOptionsJSON) {
    if (!window.isSecureContext) {
      return {
        success: false,
        retry: false,
        error: __('The application is not running in a secure context.'),
      }
    }
    try {
      const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(publicKeyOptions)
      const credential = (await navigator.credentials.create({ publicKey })) as PublicKeyCredential

      if (!credential || credential.type !== 'public-key') {
        throw new Error()
      }

      return {
        success: true,
        payload: {
          challenge: publicKeyOptions.challenge,
          credential: credential.toJSON(),
        },
      }
    } catch {
      return {
        success: false,
        retry: true,
        error: __('Security key setup failed.'),
      }
    }
  },
} satisfies TwoFactorConfigurationPlugin
