import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './delete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketLiveUserDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.TicketLiveUserDeleteMutation, Types.TicketLiveUserDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketLiveUserDeleteDocument, defaults)
}

export function waitForTicketLiveUserDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketLiveUserDeleteMutation>(Operations.TicketLiveUserDeleteDocument)
}

export function mockTicketLiveUserDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketLiveUserDeleteDocument, message, extensions);
}
