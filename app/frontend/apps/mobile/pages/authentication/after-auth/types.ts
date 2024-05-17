// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumAfterAuthType } from '#shared/graphql/types.ts'

import type { Component } from 'vue'

export interface AfterAuthPlugin {
  name: EnumAfterAuthType
  title: string
  component: Component
}
