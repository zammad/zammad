import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartSingle.api.ts'

export function mockTicketSharedDraftStartSingleQuery(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartSingleQuery, Types.TicketSharedDraftStartSingleQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartSingleDocument, defaults)
}

export function waitForTicketSharedDraftStartSingleQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartSingleQuery>(Operations.TicketSharedDraftStartSingleDocument)
}
