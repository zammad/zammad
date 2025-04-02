import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSharedDraftStartUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartUpdateMutation, Types.TicketSharedDraftStartUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartUpdateDocument, defaults)
}

export function waitForTicketSharedDraftStartUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartUpdateMutation>(Operations.TicketSharedDraftStartUpdateDocument)
}

export function mockTicketSharedDraftStartUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSharedDraftStartUpdateDocument, message, extensions);
}
