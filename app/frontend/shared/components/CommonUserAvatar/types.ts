// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export interface AvatarUser {
  lastname?: string
  firstname?: string
  email?: string
  vip?: boolean
  outOfOffice?: boolean
  active?: boolean
  image?: string
  id: string
  source?: string
}
