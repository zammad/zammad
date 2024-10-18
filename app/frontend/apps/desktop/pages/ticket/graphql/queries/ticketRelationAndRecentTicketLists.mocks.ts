import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketRelationAndRecentTicketLists.api.ts'

export function mockTicketRelationAndRecentTicketListsQuery(defaults: Mocks.MockDefaultsValue<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketRelationAndRecentTicketListsDocument, defaults)
}

export function waitForTicketRelationAndRecentTicketListsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketRelationAndRecentTicketListsQuery>(Operations.TicketRelationAndRecentTicketListsDocument)
}
