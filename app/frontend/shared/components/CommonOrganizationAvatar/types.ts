// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export interface AvatarOrganization {
  id: string
  name?: Maybe<string>
  active?: Maybe<boolean>
  vip?: Maybe<boolean>
}

export interface OrganizationAvatarClassMap {
  base: string
  inactive: string
}
