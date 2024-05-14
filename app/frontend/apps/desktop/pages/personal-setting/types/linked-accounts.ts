// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumAuthenticationProvider } from '#shared/graphql/types.ts'

export interface LinkedAccountTableItem {
  id: number
  application: string
  username: string
  uid: string
  name: EnumAuthenticationProvider
  url: string
  enabled: boolean
  authorizationId: string
}
