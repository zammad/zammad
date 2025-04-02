import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftZoomDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketSharedDraftZoomDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftZoomDeleteMutation, Types.TicketSharedDraftZoomDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftZoomDeleteDocument, defaults)
}

export function waitForTicketSharedDraftZoomDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftZoomDeleteMutation>(Operations.TicketSharedDraftZoomDeleteDocument)
}

export function mockTicketSharedDraftZoomDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketSharedDraftZoomDeleteDocument, message, extensions);
}
