import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTicketOverviews.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTicketOverviewsQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTicketOverviewsQuery, Types.UserCurrentTicketOverviewsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTicketOverviewsDocument, defaults)
}

export function waitForUserCurrentTicketOverviewsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTicketOverviewsQuery>(Operations.UserCurrentTicketOverviewsDocument)
}

export function mockUserCurrentTicketOverviewsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTicketOverviewsDocument, message, extensions);
}
