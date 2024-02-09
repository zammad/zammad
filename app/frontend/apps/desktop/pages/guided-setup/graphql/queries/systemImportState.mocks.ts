import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemImportState.api.ts'

export function mockSystemImportStateQuery(defaults: Mocks.MockDefaultsValue<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemImportStateDocument, defaults)
}

export function waitForSystemImportStateQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemImportStateQuery>(Operations.SystemImportStateDocument)
}
