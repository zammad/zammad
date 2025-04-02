import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorConfiguration.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTwoFactorConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorConfigurationDocument, defaults)
}

export function waitForUserCurrentTwoFactorConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorConfigurationQuery>(Operations.UserCurrentTwoFactorConfigurationDocument)
}

export function mockUserCurrentTwoFactorConfigurationQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTwoFactorConfigurationDocument, message, extensions);
}
