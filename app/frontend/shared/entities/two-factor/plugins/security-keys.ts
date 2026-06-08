// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumTwoFactorAuthenticationMethod } from '#shared/graphql/types.ts'

import type { TwoFactorPlugin } from '../types.ts'

export default {
  name: EnumTwoFactorAuthenticationMethod.SecurityKeys,
  label: __('Security keys'),
  description: __('Complete the sign-in with your security key.'),
  order: 100,
  icon: '2fa-security-keys',
  loginOptions: {
    helpMessage: __('Verifying key information…'),
    errorHelpMessage: __('Try using your security key again.'),
    form: false,
    async setup(publicKeyOptions: PublicKeyCredentialRequestOptionsJSON) {
      if (!window.isSecureContext) {
        return {
          success: false,
          retry: false,
          error: __('The application is not running in a secure context.'),
        }
      }
      try {
        const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(publicKeyOptions)
        const credential = (await navigator.credentials.get({ publicKey })) as PublicKeyCredential

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
          error: __('Security key verification failed.'),
        }
      }
    },
  },
} satisfies TwoFactorPlugin
