import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSharedDraftStartDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartDeleteMutation, Types.TicketSharedDraftStartDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartDeleteDocument, defaults)
}

export function waitForTicketSharedDraftStartDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartDeleteMutation>(Operations.TicketSharedDraftStartDeleteDocument)
}

export function mockTicketSharedDraftStartDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSharedDraftStartDeleteDocument, message, extensions);
}
