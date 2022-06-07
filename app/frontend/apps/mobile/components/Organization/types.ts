// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export interface OrganizationItemData {
  id: string
  ticketsCount: number
  members?: {
    lastname?: Maybe<string>
    firstname?: Maybe<string>
  }[]
  active: boolean
  name: string
  updatedAt?: string
  updatedBy?: {
    id: string
    firstname?: Maybe<string>
    lastname?: Maybe<string>
  }
}
