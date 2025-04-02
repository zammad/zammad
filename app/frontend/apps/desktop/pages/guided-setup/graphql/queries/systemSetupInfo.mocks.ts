import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemSetupInfo.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSystemSetupInfoQuery(defaults: Mocks.MockDefaultsValue<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemSetupInfoDocument, defaults)
}

export function waitForSystemSetupInfoQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemSetupInfoQuery>(Operations.SystemSetupInfoDocument)
}

export function mockSystemSetupInfoQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SystemSetupInfoDocument, message, extensions);
}
