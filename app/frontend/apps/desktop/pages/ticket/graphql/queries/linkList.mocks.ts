import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './linkList.api.ts'

export function mockLinkListQuery(defaults: Mocks.MockDefaultsValue<Types.LinkListQuery, Types.LinkListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.LinkListDocument, defaults)
}

export function waitForLinkListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.LinkListQuery>(Operations.LinkListDocument)
}
