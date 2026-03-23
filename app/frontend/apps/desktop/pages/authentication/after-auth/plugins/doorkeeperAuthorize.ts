// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EnumAfterAuthType } from '#shared/graphql/types.ts'

import DoorKeeperAuthorize from '../../components/AfterAuth/DoorKeeperAuthorize.vue'

import type { AfterAuthPlugin } from '../types.ts'

export default {
  name: EnumAfterAuthType.DoorKeeperAuthorize,
  title: __('Redirecting to authorization…'),
  component: DoorKeeperAuthorize,
} satisfies AfterAuthPlugin
