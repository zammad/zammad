import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './overviewsWithCachedCount.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockOverviewsWithCachedCountQuery(defaults: Mocks.MockDefaultsValue<Types.OverviewsWithCachedCountQuery, Types.OverviewsWithCachedCountQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.OverviewsWithCachedCountDocument, defaults)
}

export function waitForOverviewsWithCachedCountQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.OverviewsWithCachedCountQuery>(Operations.OverviewsWithCachedCountDocument)
}

export function mockOverviewsWithCachedCountQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.OverviewsWithCachedCountDocument, message, extensions);
}
