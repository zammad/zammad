import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartDelete.api.ts'

export function mockTicketSharedDraftStartDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartDeleteMutation, Types.TicketSharedDraftStartDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartDeleteDocument, defaults)
}

export function waitForTicketSharedDraftStartDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartDeleteMutation>(Operations.TicketSharedDraftStartDeleteDocument)
}
