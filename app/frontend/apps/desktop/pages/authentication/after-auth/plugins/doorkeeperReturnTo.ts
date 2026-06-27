// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumAfterAuthType } from '#shared/graphql/types.ts'

import DoorkeeperReturnTo from '../../components/AfterAuth/DoorkeeperReturnTo.vue'

import type { AfterAuthPlugin } from '../types.ts'

export default {
  name: EnumAfterAuthType.DoorkeeperReturnTo,
  title: __('Redirecting to authorization…'),
  component: DoorkeeperReturnTo,
} satisfies AfterAuthPlugin
