import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftZoomCreate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSharedDraftZoomCreateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftZoomCreateMutation, Types.TicketSharedDraftZoomCreateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftZoomCreateDocument, defaults)
}

export function waitForTicketSharedDraftZoomCreateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftZoomCreateMutation>(Operations.TicketSharedDraftZoomCreateDocument)
}

export function mockTicketSharedDraftZoomCreateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSharedDraftZoomCreateDocument, message, extensions);
}
