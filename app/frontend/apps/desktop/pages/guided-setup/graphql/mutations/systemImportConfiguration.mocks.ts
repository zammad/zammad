import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemImportConfiguration.api.ts'

export function mockSystemImportConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.SystemImportConfigurationMutation, Types.SystemImportConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemImportConfigurationDocument, defaults)
}

export function waitForSystemImportConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemImportConfigurationMutation>(Operations.SystemImportConfigurationDocument)
}
