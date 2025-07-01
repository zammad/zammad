import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './todaysTickets.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTodaysTicketsQuery(defaults: Mocks.MockDefaultsValue<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TodaysTicketsDocument, defaults)
}

export function waitForTodaysTicketsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TodaysTicketsQuery>(Operations.TodaysTicketsDocument)
}

export function mockTodaysTicketsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TodaysTicketsDocument, message, extensions);
}
