// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumAfterAuthType } from '#shared/graphql/types.ts'

import TwoFactorConfiguration from '../../components/AfterAuth/TwoFactorConfiguration.vue'

import type { AfterAuthPlugin } from '../types.ts'

export default {
  name: EnumAfterAuthType.TwoFactorConfiguration,
  component: TwoFactorConfiguration,
  title: __('Two-factor authentication configuration is required'),
} satisfies AfterAuthPlugin
