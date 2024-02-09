import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemImportStart.api.ts'

export function mockSystemImportStartMutation(defaults: Mocks.MockDefaultsValue<Types.SystemImportStartMutation, Types.SystemImportStartMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemImportStartDocument, defaults)
}

export function waitForSystemImportStartMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemImportStartMutation>(Operations.SystemImportStartDocument)
}
