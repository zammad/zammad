import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorInitiateMethodConfiguration.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTwoFactorInitiateMethodConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery, Types.UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorInitiateMethodConfigurationDocument, defaults)
}

export function waitForUserCurrentTwoFactorInitiateMethodConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery>(Operations.UserCurrentTwoFactorInitiateMethodConfigurationDocument)
}

export function mockUserCurrentTwoFactorInitiateMethodConfigurationQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTwoFactorInitiateMethodConfigurationDocument, message, extensions);
}
