import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemSetupInfo.api.ts'

export function mockSystemSetupInfoQuery(defaults: Mocks.MockDefaultsValue<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemSetupInfoDocument, defaults)
}

export function waitForSystemSetupInfoQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemSetupInfoQuery>(Operations.SystemSetupInfoDocument)
}
