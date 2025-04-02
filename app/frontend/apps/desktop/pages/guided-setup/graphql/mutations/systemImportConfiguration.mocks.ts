import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemImportConfiguration.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSystemImportConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.SystemImportConfigurationMutation, Types.SystemImportConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemImportConfigurationDocument, defaults)
}

export function waitForSystemImportConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemImportConfigurationMutation>(Operations.SystemImportConfigurationDocument)
}

export function mockSystemImportConfigurationMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SystemImportConfigurationDocument, message, extensions);
}
