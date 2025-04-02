import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketRelationAndRecentTicketLists.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketRelationAndRecentTicketListsQuery(defaults: Mocks.MockDefaultsValue<Types.TicketRelationAndRecentTicketListsQuery, Types.TicketRelationAndRecentTicketListsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketRelationAndRecentTicketListsDocument, defaults)
}

export function waitForTicketRelationAndRecentTicketListsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketRelationAndRecentTicketListsQuery>(Operations.TicketRelationAndRecentTicketListsDocument)
}

export function mockTicketRelationAndRecentTicketListsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketRelationAndRecentTicketListsDocument, message, extensions);
}
