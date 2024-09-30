// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { Ticket } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import type { ResolversMeta } from '../builders/index.ts'

export default (
  _parent: unknown,
  _value: unknown,
  meta: ResolversMeta,
): DeepPartial<Ticket> => {
  const permissions = Reflect.get(
    globalThis,
    Symbol.for('tests.permissions'),
  ) as { names: string[] } | undefined
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
      agentReadAccess: !!permissions?.names.includes('ticket.agent'),
    },
    createArticleType: {
      __typename: 'TicketArticleType',
      id: convertToGraphQLId('TicketArticleType', 1),
      name: 'email',
      communication: false,
    },
    checklist: null,
    referencingChecklistTickets: [],
  }
  if (meta.variables.ticketNumber) {
    ticket.number = meta.variables.ticketNumber as string
  }
  return ticket
}
