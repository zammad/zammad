import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsCachedByOverview.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsCachedByOverviewQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsCachedByOverviewQuery, Types.TicketsCachedByOverviewQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsCachedByOverviewDocument, defaults)
}

export function waitForTicketsCachedByOverviewQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsCachedByOverviewQuery>(Operations.TicketsCachedByOverviewDocument)
}

export function mockTicketsCachedByOverviewQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsCachedByOverviewDocument, message, extensions);
}
