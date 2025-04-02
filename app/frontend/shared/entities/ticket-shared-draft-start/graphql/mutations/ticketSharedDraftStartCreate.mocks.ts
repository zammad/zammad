import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartCreate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSharedDraftStartCreateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartCreateMutation, Types.TicketSharedDraftStartCreateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartCreateDocument, defaults)
}

export function waitForTicketSharedDraftStartCreateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartCreateMutation>(Operations.TicketSharedDraftStartCreateDocument)
}

export function mockTicketSharedDraftStartCreateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSharedDraftStartCreateDocument, message, extensions);
}
