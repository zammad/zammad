import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './history.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserHistoryQuery(defaults: Mocks.MockDefaultsValue<Types.UserHistoryQuery, Types.UserHistoryQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserHistoryDocument, defaults)
}

export function waitForUserHistoryQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserHistoryQuery>(Operations.UserHistoryDocument)
}

export function mockUserHistoryQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserHistoryDocument, message, extensions);
}
