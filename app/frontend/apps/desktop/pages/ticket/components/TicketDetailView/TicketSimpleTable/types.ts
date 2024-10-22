// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { Organization, User } from '#shared/graphql/types.ts'

type OrganizationType = Record<
  'organization',
  Pick<Organization, 'name' | 'id'>
>

type CustomerType = Record<'customer', Pick<User, 'fullname' | 'id'>>

type State = Record<'state', Pick<TicketById['state'], 'name' | 'id'>>

type Group = Record<'group', Pick<TicketById['group'], 'name' | 'id'>>

export type TicketRelationAndRecentListItem = Pick<
  TicketById,
  'number' | 'internalId' | 'id' | 'title' | 'createdAt' | 'stateColorCode'
> &
  OrganizationType &
  CustomerType &
  State &
  Group
