// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

export interface UserAvatarClassMap {
  backgroundColors: string[]
}
