// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'
import type { Ticket } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { ResolversMeta } from './index.ts'

export default (
  _parent: unknown,
  _value: unknown,
  meta: ResolversMeta,
): DeepPartial<Ticket> => {
  const ticket: DeepPartial<Ticket> = {
    objectAttributeValues: [],
    customer: {
      id: convertToGraphQLId('User', 1),
    },
    mentions: {
      edges: [],
      totalCount: 0,
    },
    number: faker.number.int({ min: 1, max: 10000 }).toString(),
    policy: {
      destroy: true,
      update: true,
    },
  }
  if (meta.variables.ticketNumber) {
    ticket.number = meta.variables.ticketNumber as string
  }
  return ticket
}
