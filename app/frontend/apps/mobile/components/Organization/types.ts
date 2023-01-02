// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export interface OrganizationItemData {
  id: string
  internalId: number
  ticketsCount?: {
    open: number
    closed: number
  }
  members?: {
    edges: {
      node: {
        fullname: string
      }
    }[]
    totalCount: number
  }
  active: boolean
  name: string
  updatedAt?: string
  updatedBy?: {
    id: string
    fullname?: Maybe<string>
  }
}
