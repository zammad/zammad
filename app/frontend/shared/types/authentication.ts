// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export interface ThirdPartyAuthProvider {
  name: string
  enabled: boolean
  icon: string
  url: string
}
