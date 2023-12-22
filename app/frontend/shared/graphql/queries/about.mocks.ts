import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './about.api.ts'

export function mockProductAboutQuery(defaults: Mocks.MockDefaultsValue<Types.ProductAboutQuery, Types.ProductAboutQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ProductAboutDocument, defaults)
}

export function waitForProductAboutQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ProductAboutQuery>(Operations.ProductAboutDocument)
}
