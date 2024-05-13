import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAcessTokenList.api.ts'

export function mockUserCurrentAccessTokenListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAccessTokenListDocument, defaults)
}

export function waitForUserCurrentAccessTokenListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAccessTokenListQuery>(Operations.UserCurrentAccessTokenListDocument)
}
