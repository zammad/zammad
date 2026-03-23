// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumAfterAuthType } from '#shared/graphql/types.ts'

import DoorkeeperAuthorize from '../../components/AfterAuth/DoorkeeperAuthorize.vue'

import type { AfterAuthPlugin } from '../types.ts'

export default {
  name: EnumAfterAuthType.DoorkeeperAuthorize,
  title: __('Redirecting to authorization…'),
  component: DoorkeeperAuthorize,
} satisfies AfterAuthPlugin
