// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { TicketPriority } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<TicketPriority> => {
  const id = faker.number.int({ min: 0, max: 2 })
  return {
    id: convertToGraphQLId('TicketPriority', id + 1),
    uiColor: ['high-priority', 'low-priority', 'medium-priority'][id],
    uiIcon: null,
  }
}
