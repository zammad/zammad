import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './formUpdater.api.ts'

export function mockFormUpdaterQuery(defaults: Mocks.MockDefaultsValue<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.FormUpdaterDocument, defaults)
}

export function waitForFormUpdaterQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.FormUpdaterQuery>(Operations.FormUpdaterDocument)
}
