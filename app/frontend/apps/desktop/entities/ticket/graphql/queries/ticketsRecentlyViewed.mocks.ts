import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketsRecentlyViewed.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketsRecentlyViewedQuery(defaults: Mocks.MockDefaultsValue<Types.TicketsRecentlyViewedQuery, Types.TicketsRecentlyViewedQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketsRecentlyViewedDocument, defaults)
}

export function waitForTicketsRecentlyViewedQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketsRecentlyViewedQuery>(Operations.TicketsRecentlyViewedDocument)
}

export function mockTicketsRecentlyViewedQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketsRecentlyViewedDocument, message, extensions);
}
