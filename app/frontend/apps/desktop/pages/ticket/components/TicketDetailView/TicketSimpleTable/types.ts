// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { Organization, User } from '#shared/graphql/types.ts'

import type { TableItem } from '#desktop/components/CommonSimpleTable/types.ts'

type OrganizationType = Pick<Organization, 'name'>

type CustomerType = Pick<User, 'fullname'>

type State = Pick<TicketById['state'], 'name'>

export type TicketTableData = Pick<
  TicketById,
  'number' | 'internalId' | 'id' | 'title' | 'createdAt' | 'stateColorCode'
> &
  TableItem &
  OrganizationType &
  CustomerType &
  State
