import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketLiveUserUpsert.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketLiveUserUpsertMutation(defaults: Mocks.MockDefaultsValue<Types.TicketLiveUserUpsertMutation, Types.TicketLiveUserUpsertMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketLiveUserUpsertDocument, defaults)
}

export function waitForTicketLiveUserUpsertMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketLiveUserUpsertMutation>(Operations.TicketLiveUserUpsertDocument)
}

export function mockTicketLiveUserUpsertMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketLiveUserUpsertDocument, message, extensions);
}
