// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export interface AvatarUser {
  lastname?: Maybe<string>
  firstname?: Maybe<string>
  fullname?: Maybe<string>
  email?: Maybe<string>
  vip?: Maybe<boolean>
  outOfOffice?: Maybe<boolean>
  active?: Maybe<boolean>
  image?: Maybe<string>
  id: string
  source?: string
}
