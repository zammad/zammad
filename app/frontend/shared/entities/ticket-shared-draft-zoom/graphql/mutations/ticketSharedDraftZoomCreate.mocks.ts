import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftZoomCreate.api.ts'

export function mockTicketSharedDraftZoomCreateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftZoomCreateMutation, Types.TicketSharedDraftZoomCreateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftZoomCreateDocument, defaults)
}

export function waitForTicketSharedDraftZoomCreateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftZoomCreateMutation>(Operations.TicketSharedDraftZoomCreateDocument)
}
