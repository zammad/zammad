// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { EnumAuthenticationProvider } from '#shared/graphql/types.ts'

export interface ThirdPartyAuthProvider {
  name: EnumAuthenticationProvider
  label: string
  enabled: boolean
  icon: string
  url: string
}
