import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOverviewList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentOverviewListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOverviewListDocument, defaults)
}

export function waitForUserCurrentOverviewListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOverviewListQuery>(Operations.UserCurrentOverviewListDocument)
}

export function mockUserCurrentOverviewListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentOverviewListDocument, message, extensions);
}
