import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './quickSearch.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockQuickSearchQuery(defaults: Mocks.MockDefaultsValue<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.QuickSearchDocument, defaults)
}

export function waitForQuickSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.QuickSearchQuery>(Operations.QuickSearchDocument)
}

export function mockQuickSearchQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.QuickSearchDocument, message, extensions);
}
