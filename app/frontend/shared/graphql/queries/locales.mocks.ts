import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './locales.api.ts'

export function mockLocalesQuery(defaults: Mocks.MockDefaultsValue<Types.LocalesQuery, Types.LocalesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.LocalesDocument, defaults)
}

export function waitForLocalesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.LocalesQuery>(Operations.LocalesDocument)
}
