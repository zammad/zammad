import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftZoomUpdate.api.ts'

export function mockTicketSharedDraftZoomUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftZoomUpdateMutation, Types.TicketSharedDraftZoomUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftZoomUpdateDocument, defaults)
}

export function waitForTicketSharedDraftZoomUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftZoomUpdateMutation>(Operations.TicketSharedDraftZoomUpdateDocument)
}
