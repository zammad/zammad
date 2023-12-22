import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './applicationConfig.api.ts'

export function mockApplicationConfigQuery(defaults: Mocks.MockDefaultsValue<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ApplicationConfigDocument, defaults)
}

export function waitForApplicationConfigQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ApplicationConfigQuery>(Operations.ApplicationConfigDocument)
}
