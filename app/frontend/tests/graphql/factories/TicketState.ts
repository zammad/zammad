// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { TicketState } from '#shared/graphql/types.ts'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { updateGeneratedIds } from '../builders/utils.ts'

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
