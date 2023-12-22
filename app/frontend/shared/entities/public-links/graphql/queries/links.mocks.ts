import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './links.api.ts'

export function mockPublicLinksQuery(defaults: Mocks.MockDefaultsValue<Types.PublicLinksQuery, Types.PublicLinksQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.PublicLinksDocument, defaults)
}

export function waitForPublicLinksQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.PublicLinksQuery>(Operations.PublicLinksDocument)
}
