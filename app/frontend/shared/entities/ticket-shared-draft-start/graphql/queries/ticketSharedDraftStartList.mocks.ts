import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartList.api.ts'

export function mockTicketSharedDraftStartListQuery(defaults: Mocks.MockDefaultsValue<Types.TicketSharedDraftStartListQuery, Types.TicketSharedDraftStartListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketSharedDraftStartListDocument, defaults)
}

export function waitForTicketSharedDraftStartListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketSharedDraftStartListQuery>(Operations.TicketSharedDraftStartListDocument)
}
