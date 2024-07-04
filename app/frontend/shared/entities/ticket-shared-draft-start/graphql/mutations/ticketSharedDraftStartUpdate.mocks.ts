import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartUpdate.api.ts'

export function mockTicketSharedDraftStartUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartUpdateMutation, Types.TicketSharedDraftStartUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartUpdateDocument, defaults)
}

export function waitForTicketSharedDraftStartUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartUpdateMutation>(Operations.TicketSharedDraftStartUpdateDocument)
}
