// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'
import type { CredentialRequestOptionsJSON } from '@github/webauthn-json'
import type { TwoFactorPlugin } from '../types.ts'

export default {
  name: EnumTwoFactorAuthenticationMethod.SecurityKeys,
  label: __('Security Keys'),
  order: 100,
  helpMessage: __('Complete the sign-in with your security key.'),
  errorHelpMessage: __('Try using your security key again.'),
  form: false,
  async setup(
    publicKey: NonNullable<CredentialRequestOptionsJSON['publicKey']>,
  ) {
    if (!window.isSecureContext) {
      return {
        success: false,
        retry: false,
        error: __('The application is not running in a secure context.'),
      }
    }
    try {
      const { get } = await import('@github/webauthn-json')
      const publicKeyCredential = await get({ publicKey })
      return {
        success: true,
        payload: {
          challenge: publicKey.challenge,
          credential: publicKeyCredential,
        },
      }
    } catch (err) {
      return {
        success: false,
        retry: true,
        error: __('Security key verification failed.'),
      }
    }
  },
  icon: '2fa-security-keys',
} satisfies TwoFactorPlugin
