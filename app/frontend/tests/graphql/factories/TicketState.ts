// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketState } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'
import { faker } from '@faker-js/faker'
import { updateGeneratedIds } from './utils.ts'

const states: (() => DeepPartial<TicketState>)[] = [
  () => ({ id: convertToGraphQLId('TicketState', 1), name: 'new' }),
  () => ({ id: convertToGraphQLId('TicketState', 2), name: 'open' }),
]

export default (): DeepPartial<TicketState> => {
  const state: DeepPartial<TicketState> = faker.helpers.arrayElement(states)()
  state.stateType = {
    id: state.id,
    name: state.name,
  }
  updateGeneratedIds('TicketState', getIdFromGraphQLId(state.id!))
  return state
}
