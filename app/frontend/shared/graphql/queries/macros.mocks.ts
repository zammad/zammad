import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './macros.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockMacrosQuery(defaults: Mocks.MockDefaultsValue<Types.MacrosQuery, Types.MacrosQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.MacrosDocument, defaults)
}

export function waitForMacrosQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.MacrosQuery>(Operations.MacrosDocument)
}

export function mockMacrosQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.MacrosDocument, message, extensions);
}
