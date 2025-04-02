import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTicketOverviewsCount.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTicketOverviewsCountQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTicketOverviewsCountQuery, Types.UserCurrentTicketOverviewsCountQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTicketOverviewsCountDocument, defaults)
}

export function waitForUserCurrentTicketOverviewsCountQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTicketOverviewsCountQuery>(Operations.UserCurrentTicketOverviewsCountDocument)
}

export function mockUserCurrentTicketOverviewsCountQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTicketOverviewsCountDocument, message, extensions);
}
