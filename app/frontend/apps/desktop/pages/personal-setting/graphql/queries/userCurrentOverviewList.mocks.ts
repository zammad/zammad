import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOverviewList.api.ts'

export function mockUserCurrentOverviewListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOverviewListQuery, Types.UserCurrentOverviewListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOverviewListDocument, defaults)
}

export function waitForUserCurrentOverviewListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOverviewListQuery>(Operations.UserCurrentOverviewListDocument)
}
