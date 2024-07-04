import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartCreate.api.ts'

export function mockTicketSharedDraftStartCreateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartCreateMutation, Types.TicketSharedDraftStartCreateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartCreateDocument, defaults)
}

export function waitForTicketSharedDraftStartCreateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartCreateMutation>(Operations.TicketSharedDraftStartCreateDocument)
}
