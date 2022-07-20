// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export interface AvatarUser {
  lastname?: Maybe<string>
  firstname?: Maybe<string>
  email?: Maybe<string>
  vip?: boolean
  outOfOffice?: boolean
  active?: boolean
  image?: Maybe<string>
  id: string
  source?: string
}
