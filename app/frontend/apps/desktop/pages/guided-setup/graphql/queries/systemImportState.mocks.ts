import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemImportState.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSystemImportStateQuery(defaults: Mocks.MockDefaultsValue<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemImportStateDocument, defaults)
}

export function waitForSystemImportStateQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemImportStateQuery>(Operations.SystemImportStateDocument)
}

export function mockSystemImportStateQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SystemImportStateDocument, message, extensions);
}
