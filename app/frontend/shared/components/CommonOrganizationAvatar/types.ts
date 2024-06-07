// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export interface AvatarOrganization {
  name?: Maybe<string>
  active?: Maybe<boolean>
  vip?: Maybe<boolean>
}

export interface OrganizationAvatarClassMap {
  base: string
  inactive: string
}
