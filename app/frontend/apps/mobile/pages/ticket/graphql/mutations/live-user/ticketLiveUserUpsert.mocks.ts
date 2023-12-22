import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketLiveUserUpsert.api.ts'

export function mockTicketLiveUserUpsertMutation(defaults: Mocks.MockDefaultsValue<Types.TicketLiveUserUpsertMutation, Types.TicketLiveUserUpsertMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketLiveUserUpsertDocument, defaults)
}

export function waitForTicketLiveUserUpsertMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketLiveUserUpsertMutation>(Operations.TicketLiveUserUpsertDocument)
}
