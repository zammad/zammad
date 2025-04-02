import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './overviews.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketOverviewsQuery(defaults: Mocks.MockDefaultsValue<Types.TicketOverviewsQuery, Types.TicketOverviewsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketOverviewsDocument, defaults)
}

export function waitForTicketOverviewsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketOverviewsQuery>(Operations.TicketOverviewsDocument)
}

export function mockTicketOverviewsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketOverviewsDocument, message, extensions);
}
