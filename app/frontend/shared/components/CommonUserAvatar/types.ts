// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTaskbarApp } from '#shared/graphql/types.ts'

export interface AvatarUser {
  lastname?: Maybe<string>
  firstname?: Maybe<string>
  fullname?: Maybe<string>
  email?: Maybe<string>
  phone?: Maybe<string>
  mobile?: Maybe<string>
  vip?: Maybe<boolean>
  outOfOffice?: Maybe<boolean>
  outOfOfficeEndAt?: Maybe<string>
  outOfOfficeStartAt?: Maybe<string>
  active?: Maybe<boolean>
  image?: Maybe<string>
  id: string
  source?: string
}

export interface AvatarUserAccess {
  agentReadAccess?: boolean
}

export interface AvatarUserLive {
  editing?: boolean
  app?: EnumTaskbarApp
  isIdle?: boolean
}

export interface UserAvatarClassMap {
  backgroundColors: string[]
}
